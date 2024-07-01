# frozen_string_literal: true

module RequestHelper
  include Authenticator

  def request_compute(resource, options = nil)
    url = service_creds('compute')['url']
    url = "#{url}/api/#{resource}?#{options}"

    RestClient::Request.execute(
      method: :get,
      url:,
      headers: {
        Authorization: "Basic #{basic_token('compute')}"
      }
    )
  end
end
