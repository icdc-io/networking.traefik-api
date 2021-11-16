class Api::V1::ServicesController < ApplicationController
  def index
    @services = Service.where(:owner => @@user_email)
    render json: @services, status: :ok
  end
end
