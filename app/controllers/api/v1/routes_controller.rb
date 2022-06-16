class Api::V1::RoutesController < ApplicationController

  def index
    render json: Route.filtered_list, status: :ok
  end

  def show
    if @route = Route.find_by(:id => params[:id])&.rbac
      render json: { route: @route }, status: :ok
    else
      render json: nil, status: :not_found
    end
  end

  def create
    services = params[:route].delete(:services)
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
      :certificate_id
    )
    unless $location_admin
      unless CloudGateway.find_by(:id => route_params[:cloud_gateway_id])&.rbac(no_owner: true)
        return not_found("Cloud Gateway with id #{route_params[:cloud_gateway_id]}")
      end
      unless $account_admin
        route_params[:owner] = $email
      end
    end
    
    @route = Route.create!(route_params)
    begin
      if services.count == 1
        if service = Service.find_by(:id => services.first['id'])&.rbac
          RoutesService.create!(
            :route => @route, 
            :service => service, 
            :balance_type => :loadbalancer, 
            :value => nil, 
            :name => "#{service.ext_id}-#{@route.target_port}"
            )
        else 
          return not_found("Service with id #{services.first['id']}")
        end
      elsif services.count > 1
        services.each do |data|
          name = RoutesService.generate_name
          if service = Service.find_by(:id => data['id'])&.rbac
            RoutesService.create!(
              :route => @route, 
              :service => service, 
              :balance_type => :weighted,
              :value => data['weight'], 
              :name => name
            )
          else
            return not_found("Service with id #{data['id']}")
          end
        end
      end
    rescue => err
      @route.destroy!
      raise err
    end
    render json: @route, status: :created
  end

  def update
    if @route = Route.find_by(:id => params[:id])&.rbac
      return render :json => @route unless params[:route]

      services = params[:route].delete(:services)

      unless $location_admin
        if params[:route][:cloud_gateway_id] &&
            !CloudGateway.find_by(:id => params[:route][:cloud_gateway_id])&.rbac(no_owner: true)
          return not_found("Cloud Gateway with id #{params[:route][:cloud_gateway_id]}")
        end
      end

      if params[:route][:certificate_id]
        if certificate = Certificate.find_by(:id => params[:route][:certificate_id])&.rbac
          @route.update!(:certificate_id => params[:route][:certificate_id])
        else
          return not_found("Certificate with id #{params[:route][:certificate_id]}")
        end
      else
        @route.update!(:certificate_id => nil)
      end

      @route.update(
        (
          params.require(:route).permit(
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
            :ip_version
          )
        ),
        services
      )

      return render json: Route.find_by(:id => params[:id]), status: :ok
    end
    render json: nil, status: :not_found
  end

  def destroy
    if @route = Route.find_by(:id => params[:id])&.rbac
      @route.destroy!
      return render json: nil, status: :no_content
    end
    render json: nil, status: :not_found
  end

end
