class ServicesAccessJob < ApplicationJob
  include RequestHelper

  queue_as :default

  def perform(*_args)
    refresh
  end

  private

  def fetch_services
    services = request_compute("services",
                               "expand=resources&attributes=networks,evm_owner,tenant")
    services.map do |service|
      {
        ext_id:      service["id"],
        name:        service["name"],
        owner:       service.dig("evm_owner", "email"),
        account:     service["tenant"]["name"],
        ipaddresses: service["networks"].collect do |network|
          network["allocations"]
        end
                                           .flatten.select do |alloc|
          alloc if alloc["type"] == "nic"
        end
                                           .collect { |alloc| alloc["ip"] }.flatten.compact.reject(&:empty?).compact.join(","),
        type:        service["type"],
        retired?:    service["retired"] || !service["retirement_state"].nil?
      }
    end
  end

  def refresh
    services = fetch_services
    to_delete = []
    to_delete << Service.where.not(ext_id: services.pluck(:ext_id))
    to_delete << Service.where(ext_id: services.select do |x|
      x if x[:retired?] || x[:type] == "ServiceAnsiblePlaybook"
    end.pluck(:ext_id))
    to_delete.flatten.each(&:destroy)
    services.reject! do |x|
      x[:retired?] || x[:type] == "ServiceAnsiblePlaybook"
    end
    find_or_build(services)
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
