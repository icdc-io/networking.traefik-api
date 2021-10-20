class Api::V1::ServicesController < ApplicationController
  def index
    @services = Service.where(:owner => @@user_email).map{ |s| { :id => s.id, :name => s.name } }
    render json: @services, status: :ok
  end
end
