class ServicesAccessJob < ApplicationJob
  include RequestHelper
  queue_as :default

  def perform(*args)
    refresh
  end

  private

  def fetch_services
    services = request_compute('services', 'expand=resources&attributes=networks,evm_owner,tenant')
    services.map do |service|
      {
        :ext_id => service["id"],
        :name => service["name"],
        :owner => service.dig("evm_owner","email"),
        :account => service["tenant"]["name"],
        :ipaddresses => service["networks"].collect{ |network| network["allocations"] }
                                           .flatten.select{ |alloc| alloc if alloc["type"] == "nic" }
                                           .collect{ |alloc| alloc["ip"] }.flatten.join(','),
        :retired? => service["retired"] || !!service["retirement_state"]
      }
    end
  end

  def refresh
    services = fetch_services
    to_delete = []
    to_delete << Service.where.not(:ext_id => services.collect{|x| x[:ext_id]})
    to_delete << Service.where(:ext_id => services.select{|x| x if x[:retired?]}.collect{|x| x[:ext_id]})

    to_delete.flatten.each(&:destroy)
    services.reject!{|x| x[:retired?]}
    find_or_build(services)
  end

  def find_or_build(services_opts)
    services_opts.each do |service_opts|
      service = Service.find_by(:ext_id => service_opts[:ext_id])
      if service
        service_opts.delete(:retired?)
        service.update!(service_opts)
      else
        service_opts.delete(:retired?)
        Service.create!(service_opts)
      end
    end
  end
end
