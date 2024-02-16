class Api::V1::RoutesController < ApplicationController
  before_action :set_route, :check_params, only: :update

  def index
    render json: Route.filtered, status: :ok
  end

  def show
    if @route = Route.filtered.find_by(id: params[:id])
      render json: { route: @route }, status: :ok
    else
      render json: nil, status: :not_found
    end
  end

  def create
    services = params[:route].delete(:services)
    healthcheck_params = nil
    healthcheck_params = params[:route].delete(:healthcheck) if params[:route][:healthcheck_enabled]
    route_params = params.require(:route).permit(
      :name,
      :hostname,
      :path,
      :target_port,
      :insecure,
      :tls_termination,
      :labels,
      :cloud_gateway_id,
      :owner,
      :source_proto,
      :destination_proto,
      :ip_version,
      :certificate_id,
      :healthcheck_enabled
    )
    unless CloudGateway.filtered.find_by(id: route_params[:cloud_gateway_id])
      return not_found("Cloud Gateway with id #{route_params[:cloud_gateway_id]}")
    end

    route_params[:owner] = User.current_user.userid if User.current_user.role == 'member'
    @route = Route.create!(route_params)

    if @route.healthcheck_enabled
      @route.create_healthcheck!(healthcheck_params.permit(:path, :scheme, :hostname, :port, :interval, :timeout, :method,
                                                           :follow_redirects, headers: {}))
    end

    begin
      if services.count == 1
        unless service = Service.filtered.find_by(id: services.first['id'])
          return not_found("Service with id #{services.first['id']}")
        end

        name = "#{service.ext_id}-#{@route.target_port}"
        number_of_routes = RoutesService.where('name like ?', "#{name}%").collect do |record|
          record.name.split('-').last.to_i
        end
        query = ((1..number_of_routes.count + 1).to_a - number_of_routes).first
        RoutesService.create!(
          route: @route,
          service:,
          balance_type: :loadbalancer,
          value: nil,
          name: "#{name}-#{query}"
        )

      elsif services.count > 1
        services.each do |data|
          name = RoutesService.generate_name
          return not_found("Service with id #{data['id']}") unless service = Service.filtered.find_by(id: data['id'])

          RoutesService.create!(
            route: @route,
            service:,
            balance_type: :weighted,
            value: data['weight'],
            name:
          )
        end
      end
    rescue StandardError => e
      @route.destroy!
      raise e
    end
    render json: @route, status: :created
  end

  def update
    services = @route_params.delete(:services)
    Route.transaction do
      update_certificate
      @route.update(sanitize_params, services)
      if @route.healthcheck_enabled
        if @route.healthcheck
          @route.healthcheck.update!(healthcheck_params)
        else
          @route.create_healthcheck!(healthcheck_params)
        end
      else
        @route.healthcheck&.destroy!
      end
    end
    render json: @route, status: :ok
  rescue StandardError => e
    render json: { message: e }, status: :bad_request
  end

  def destroy
    if @route = Route.filtered.find_by(id: params[:id])
      @route.destroy!
      return render json: nil, status: :no_content
    end
    render json: nil, status: :not_found
  end

  private

  def set_route
    @route_params = params[:route]
    @route = Route.filtered.find_by(id: params[:id])
    render json: nil, status: :not_found unless @route
  end

  def check_params
    return render json: @route unless @route_params

    cloud_gateway_id = @route_params[:cloud_gateway_id]
    return unless cloud_gateway_id && !CloudGateway.filtered.find_by(id: cloud_gateway_id)

    not_found("Cloud Gateway with id #{cloud_gateway_id}")
  end

  def update_certificate
    certificate_id = @route_params[:certificate_id]
    if certificate_id
      raise "Certificate with id #{certificate_id} not found" unless Certificate.filtered.find_by(id: certificate_id)

      @route.update!(certificate_id:)
    else
      @route.update!(certificate_id: nil)
    end
  end

  def sanitize_params
    params.require(:route).permit(params_white_list)
  end

  def params_white_list
    %w[name hostname path target_port insecure tls_termination labels cloud_gateway_id owner source_proto
       destination_proto ip_version healthcheck_enabled]
  end

  def healthcheck_params
    healthcheck_params = @route_params.delete(:healthcheck)
    healthcheck_params.permit(:path, :scheme, :hostname, :port, :interval, :timeout, :method, :follow_redirects,
                              headers: {})
  end
end
