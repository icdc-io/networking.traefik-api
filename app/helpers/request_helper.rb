module RequestHelper
  include Authenticator

  def request_compute(resource, options = nil)
    url = service_creds("compute")["url"]
    url = "#{url}/api/#{resource}?#{options}"
    response = RestClient::Request.execute(
      :method => :get,
      :url => url,
      :headers => {
        :Authorization => "Basic #{basic_token('compute')}"
      }
    )
    return JSON.parse(response.body)["resources"] if response.code == 200
    return response.code
  end
end