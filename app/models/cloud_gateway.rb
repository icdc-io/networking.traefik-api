class CloudGateway < ApplicationRecord
  attribute :cloudgw_instance, :string

  has_many :routes, dependent: :destroy
  has_many :account_certificates, class_name: "Certificate",
                                  primary_key: :account, foreign_key: :account

  validates :cloudgw_id, uniqueness: true

  after_destroy do
    FileUtils.rm_f(
      File.join(
        ENV.fetch("USERS_CERT_PATH_ARCH", "certificates/download"),
        "#{cloudgw_id}.zip"
      )
    )
  end

  def cloudgw_instance
    "cloudgw-#{cloudgw_id.split('-').first}"
  end

  def config
    generated_config = config_template

    routes_config(generated_config)
    certificates_config(generated_config)

    compact_config(generated_config).to_yaml.strip
  end

  private

  def config_template
    {
      "http" => {
        "routers"     => internal_ping_router,
        "middlewares" => {},
        "services"    => {}
      },
      "tcp"  => {
        "routers"     => {},
        "middlewares" => {},
        "services"    => {}
      },
      # TODO: UDP?
      "tls"  => {}
    }
  end

  def internal_ping_router
    {
      "alb-ping-internal" => {
        "service"     => "ping@internal",
        "rule"        => "Host(`#{account}.alb.#{ENV.fetch('LOCATION_DOMAIN')}`) " \
                         "&& Path(`/alb/ping`)",
        "entryPoints" => [ "web" ]
      }
    }
  end

  def routes_config(generated_config)
    routes.find_each { |route| route.merge_config(generated_config) }

    generated_config
  end

  def certificates_config(generated_config)
    return generated_config if account_certificates.none?

    path = "#{ENV.fetch('TRAEFIK_CERT_PATH', '/etc/traefik')}" \
           "/certificates/#{cloudgw_id}/"

    generated_config["tls"]["certificates"] =
      account_certificates.config(path:)

    generated_config
  end

  def compact_config(generated_config)
    generated_config.each do |name, section|
      section.delete_if { |_key, value| value.empty? }

      generated_config.delete(name) if section.empty?
    end

    generated_config
  end
end
