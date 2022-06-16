class Api::V1::ServicesController < ApplicationController
  def index
    render json: Service.filtered_list, status: :ok
  end
end
