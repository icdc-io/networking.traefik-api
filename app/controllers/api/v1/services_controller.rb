class Api::V1::ServicesController < ApplicationController
  def index
    if $location_admin
      @services = Service.all
    elsif $account_admin
      @services = Service.where(:account => $current_account)
    else
      @services = Service.where(:account => $current_account, :owner => @@email)
    end

    render json: @services, status: :ok
  end
end
