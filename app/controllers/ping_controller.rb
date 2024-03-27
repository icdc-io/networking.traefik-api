# frozen_string_literal: true

class PingController < ApplicationController
  skip_before_action :authorize, :authorize_action

  def ping
    render body: 'PONG', status: :ok
  end
end
