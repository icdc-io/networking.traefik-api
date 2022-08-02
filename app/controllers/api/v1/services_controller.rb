class Api::V1::ServicesController < ApplicationController
  def index
    render json: Service.filtered, status: :ok
  end
end
