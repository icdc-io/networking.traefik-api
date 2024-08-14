# frozen_string_literal: true

class DeleteServicesJob < ApplicationJob
  include RequestHelper

  def perform
    service_ids = active_services_ids
    return if service_ids.blank?

    Service.where.not(ext_id: service_ids).destroy_all
  end

  def active_services_ids
    resp = request_compute('services', 'expand=resources')
    return [] unless resp.code == 200

    body = JSON.parse(resp.body)
    body['resources'].filter_map { |service| service['id'] }
  rescue StandardError => e
    Rails.logger.debug { "Something went wrong, #{e.message}" }
    []
  end
end
