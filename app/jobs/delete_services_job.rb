# frozen_string_literal: true

class DeleteServicesJob < ApplicationJob
  include RequestHelper

  def perform
    Service.where(ext_id: retired_services_ids).destroy_all
  end

  def retired_services_ids
    resp = request_compute('services', 'expand=resources')

    if resp.code == 200
      body = JSON.parse resp.body
      return body['resources'].filter_map { |s| s['id'] if !s['retirement_state'].nil? || s['retired'] }
    end

    []
  rescue StandardError => e
    Rails.logger.debug { "Something went wrong, #{e.message}" }
    []
  end
end
