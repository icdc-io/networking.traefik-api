class ServicesAccessJob < ApplicationJob
  include RequestHelper

  queue_as :default

  def perform(*_args)
    refresh
  end

  private

  def refresh
    services = fetch_services.reject do |x|
      x[:retired?] || x[:type] == "ServiceAnsiblePlaybook"
    end
    Service.where.not(ext_id: services.pluck(:ext_id)).destroy_all
    find_or_build(services)
  end

  def fetch_services
    services = request_compute(
      "services",
      "expand=resources&attributes=networks,evm_owner,tenant"
    )

    services.map { |service| parse_raw_service(service) }
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
        service.update!(service_opts) unless service[:ipaddresses].empty?
      else
        Service.create!(service_opts)
      end
    end
  end
end
