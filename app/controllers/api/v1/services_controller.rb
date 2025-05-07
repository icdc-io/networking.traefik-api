# frozen_string_literal: true

module Api
  module V1
    class ServicesController < ApplicationController
      def index
        set_error_code('031')
        render json: Service.filtered, status: :ok
      end
    end
  end
end
