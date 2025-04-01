# frozen_string_literal: true

module Api
  module V1
    class ServicesController < ApplicationController
      def index
        render json: Service.filtered, status: :ok
      end
    end
  end
end
