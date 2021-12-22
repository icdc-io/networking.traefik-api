class Api::V1::ServicesController < ApplicationController
  def index
    if $location_admin
      @services = Service.all
    else
      @services = Service.where(:owner => @@email)
    end

    render json: @services, status: :ok
  end
end
