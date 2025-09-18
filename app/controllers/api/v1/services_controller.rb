module Api
  module V1
    class ServicesController < ApplicationController
      def index
        set_error_code("030")
        render json: Service.filtered, status: :ok
      end
    end
  end
end
