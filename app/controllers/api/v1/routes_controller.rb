class Api::V1::RoutesController < ApplicationController

  def index
    render json: Route.filtered, status: :ok
  end

  def show
    if @route = Route.filtered.find_by(:id => params[:id])
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
    unless CloudGateway.filtered.find_by(:id => route_params[:cloud_gateway_id])
      return not_found("Cloud Gateway with id #{route_params[:cloud_gateway_id]}")
    end

    route_params[:owner] = User.current_user.userid if User.current_user.role == "member"
    
    @route = Route.create!(route_params)
    begin
      if services.count == 1
        if service = Service.filtered.find_by(:id => services.first['id'])
          name = "#{service.ext_id}-#{@route.target_port}"
          number_of_routes = RoutesService.where("name like ?", "#{name}%").collect { |record| record.name.split('-').last.to_i }
          query = ((1..number_of_routes.count + 1).to_a - number_of_routes).first
          RoutesService.create!(
            :route => @route, 
            :service => service, 
            :balance_type => :loadbalancer, 
            :value => nil, 
            :name => "#{name}-#{query}"
            )
        else 
          return not_found("Service with id #{services.first['id']}")
        end
      elsif services.count > 1
        services.each do |data|
          name = RoutesService.generate_name
          if service = Service.filtered.find_by(:id => data['id'])
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
    if @route = Route.filtered.find_by(:id => params[:id])
      return render :json => @route unless params[:route]

      services = params[:route].delete(:services)

      if params[:route][:cloud_gateway_id] &&
          !CloudGateway.filtered.find_by(:id => params[:route][:cloud_gateway_id])
        return not_found("Cloud Gateway with id #{params[:route][:cloud_gateway_id]}")
      end

      if params[:route][:certificate_id]
        if certificate = Certificate.filtered.find_by(:id => params[:route][:certificate_id])
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
    if @route = Route.filtered.find_by(:id => params[:id])
      @route.destroy!
      return render json: nil, status: :no_content
    end
    render json: nil, status: :not_found
  end

end
