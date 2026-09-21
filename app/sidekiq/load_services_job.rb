class LoadServicesJob < ApplicationJob
  include RequestHelper

  # Raised when Compute keeps failing, so a partial list of services is never
  # treated as the full one
  class ComputeUnavailable < StandardError; end

  BATCH_SIZE = 50
  MAX_RETRIES = 4
  RETRY_DELAY = 5 # seconds, doubled on every retry

  queue_as :default

  def perform(*_args)
    refresh
  end

  private

  def refresh
    known_ext_ids = []

    each_batch do |batch|
      alive = batch.map { |service| parse_raw_service(service) }
                   .reject { |service| skip?(service) }
      known_ext_ids.concat(alive.pluck(:ext_id))
      find_or_build(alive)
    end

    drop_missing_services(known_ext_ids)
  rescue ComputeUnavailable => error
    # NOTE: services are kept as is, an incomplete listing would delete the
    # ones that are still alive
    Rails.logger.error { "services are not refreshed: #{error.message}" }
  end

  def skip?(service)
    service[:retired?] || service[:type] == "ServiceAnsiblePlaybook"
  end

  # Walks over Compute services page by page and yields every batch, so a
  # single response is never bigger than BATCH_SIZE
  def each_batch
    offset = 0

    loop do
      body = fetch_batch(offset)
      resources = body["resources"] || []
      break if resources.empty?

      yield resources

      offset += BATCH_SIZE
      break if offset >= body["count"].to_i
    end
  end

  # Returns a parsed page or raises once Compute is out of retries
  def fetch_batch(offset, retries = 0)
    response = request_batch(offset)
    return JSON.parse(response.body) if response.code == 200

    if retries >= MAX_RETRIES # to avoid infinite loop
      raise ComputeUnavailable,
            "got #{response.code} at offset #{offset}"
    end

    sleep(backoff(retries))
    fetch_batch(offset, retries + 1)
  end

  # Gives Compute more room on every attempt: 5s, 10s, 20s, 40s
  def backoff(retries)
    delay = RETRY_DELAY * (2**retries)
    Rails.logger.warn { "compute retry ##{retries + 1} in #{delay}s" }
    delay
  end

  def request_batch(offset)
    request_compute(
      "services",
      "expand=resources&attributes=networks,evm_owner,tenant&" \
      "offset=#{offset}&limit=#{BATCH_SIZE}"
    )
  end

  # Services retired or removed in Compute are gone for good, drop them along
  # with their routes
  def drop_missing_services(known_ext_ids)
    return if known_ext_ids.empty?

    services = Service.where.not(ext_id: known_ext_ids)
    Rails.logger.debug { "services dropped: #{services.pluck(:ext_id)}" }
    services.destroy_all
  end

  def parse_raw_service(service)
    {
      ext_id:      service["id"],
      name:        service["name"],
      owner:       service.dig("evm_owner", "email"),
      account:     service["tenant"]["name"],
      ipaddresses: parse_ip_addresses(service["networks"]),
      type:        service["type"],
      retired?:    service["retired"] || !service["retirement_state"].nil?
    }
  end

  def parse_id_addresses(networks)
    networks.flat_map do |network|
      network["allocations"].filter_map do |alloc|
        alloc["type"] == "nic" && alloc["ip"].presence
      end
    end.join(",")
  end

  def find_or_build(services_opts)
    services_opts.each do |service_opts|
      service = Service.find_by(ext_id: service_opts[:ext_id])
      service_opts.except!(:retired?, :type)
      if service
        update_service(service, service_opts)
      else
        Rails.logger.debug { "a new service stored: #{service_opts}" }
        Service.create!(service_opts)
      end
    end
  end

  def update_service(service, service_opts)
    # NOTE: keep known addresses instead of wiping them with an empty list
    return if service_opts[:ipaddresses].empty?

    Rails.logger.debug do
      "service updated: #{service.attributes} -> #{service_opts}"
    end
    service.update!(service_opts)
  end
end
