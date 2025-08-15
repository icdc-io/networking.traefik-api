class LoadServicesJob < ApplicationJob
  include RequestHelper

  def perform
    @services = []
    service_list(50)

    @services.flatten.each do |s|
      service = parse_raw_service(s)
      next if service[:retired?]

      store_or_update_service(service)
    end.count
  end

  def service_list(limit = 50, offset = 0, iter = 0)
    response = request_compute(
      "services",
      "expand=resources&attributes=networks,evm_owner,tenant&" \
      "offset=#{offset}&limit=#{limit}"
    )
    if response.code == 200
      response = JSON.parse response.body
      return if offset > response["count"]

      @services << response["resources"]
      service_list(limit, offset + limit)
    else
      return if iter > 4 # to avoid infinity loop

      service_list(limit, offset, i + 1)
    end
  end

  def store_or_update_service(service_opts)
    return if service_opts[:type] == "ServiceAnsiblePlaybook"

    service = Service.find_by(ext_id: service_opts[:ext_id])
    if service
      Rails.logger.debug do
        "service updated: #{service.attributes} -> " \
          "#{service_opts.except(:type, :retired?)}"
      end
      unless service_opts[:ipaddresses].empty?
        service.update!(service_opts.except(:type,
                                            :retired?))
      end
    else
      service_opts.except!(:type, :retired?)
      Rails.logger.debug { "a new service stored: #{service_opts}" }
      Service.create!(service_opts)
    end
  end

  def parse_raw_service(service)
    {
      ext_id:      service["id"],
      name:        service["name"],
      owner:       service.dig("evm_owner", "email"),
      account:     service["tenant"]["name"],
      ipaddresses: parse_id_addresses(service["networks"]),
      type:        service["type"],
      retired?:    service["retired"] || !service["retirement_state"].nil?
    }
  end

  private

  def parse_id_addresses(networks)
    networks.flat_map do |network|
      network["allocations"].filter_map do |alloc|
        alloc["type"] == "nic" && alloc["ip"].presence
      end
    end.join(",")
  end
end
