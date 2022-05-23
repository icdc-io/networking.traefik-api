class Api::V1::RoutesController < ApplicationController

  def index
    if $location_admin
      @routes = Route.all
    elsif $account_admin
      @routes = Route.select{|route| route.cloud_gateway.account == $current_account}
    else
      @routes = Route.select{|route| route.owner == @@email  && route.cloud_gateway.account == $current_account}
    end
    render json: @routes, status: :ok
  end

  def show
    if @route = Route.find_by(:id => params[:id])
      if $location_admin || 
          (@route.cloud_gateway.account == $current_account && ($account_admin || @route.owner == @@email))
        return render json: { route: @route }, status: :ok
      end
    end
    render json: nil, status: :not_found
  end

  def create
    services = params[:route].delete(:services)
    certificate_id = params[:route].delete(:certificate_id)
    #### ahrechushkin: DELETE IT AFTER FIXES ON FRONTEND
    cloudgw_id = CloudGateway.find_by(:account => $current_account).id
    params[:route][:cloud_gateway_id] = cloudgw_id
    ### END
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
      :ip_version
    )
    unless $location_admin
      unless CloudGateway.find_by(:id => route_params[:cloud_gateway_id]).account == $current_account
        return not_found("Cloud Gateway with id #{route_params[:cloud_gateway_id]}")
      end
      unless $account_admin
        route_params[:owner] = @@email
      end
    end
    
    @route = Route.create!(route_params)
    if certificate_id
      if certificate = Certificate.find_by(:id => certificate_id)
        if $location_admin ||
            (certificate.account == $current_account && ($account_admin || certificate.owner == @@email))
          @route.update!(:certificate_id => certificate_id)
        else
          return not_found("Certificate with id #{certificate_id}")
        end
      else
        return not_found("Certificate with id #{certificate_id}")
      end
    end


    if services.count == 1
      service = Service.find_by(:id => services.first['id'])
      if $location_admin ||
        (service.account == $current_account && ($account_admin || service.owner == @@email))

        RoutesService.create!(
          :route => @route, 
          :service => service, 
          :balance_type => :loadbalancer, 
          :value => nil, 
          :name => service.name
          )
      else 
        return not_found("Service with id #{services.first['id']}")
      end
    elsif services.count > 1
      service = Service.find_by(:id => data['id'])
      if $location_admin ||
        (service.account == $current_account && ($account_admin || service.owner == @@email))
        name = RoutesService.generate_name
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

    render json: @route, status: :created
  end

  def update
    if @route = Route.find_by(:id => params[:id])

      if $location_admin ||
          (@route.cloud_gateway.account == $current_account && ($account_admin || @route.owner == @@email))
        return render :json => @route unless params[:route]
        
        services = params[:route].delete(:services)
  
        unless $location_admin
          if params[:route][:cloud_gateway_id] && 
              CloudGateway.find_by(:id => params[:route][:cloud_gateway_id])&.account != $current_account 
            return not_found("Cloud Gateway with id #{params[:route][:cloud_gateway_id]}")
          end
        end
    
        if params[:route][:certificate_id]
          certificate = Certificate.find_by(:id => params[:route][:certificate_id])
          if certificate && ($location_admin ||
              (certificate.account == $current_account && ($account_admin || certificate.owner == @@email)))
            @route.update!(:certificate_id => params[:route][:certificate_id])
          else
            return not_found("Certificate with id #{params[:route][:certificate_id]}")
          end
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
    end
      render json: nil, status: :not_found 
  end

  def destroy
    if @route = Route.find_by(:id => params[:id])
      if $location_admin ||
          (@route.cloud_gateway.account == $current_account && ($account_admin || @route.owner == @@email))
        @route.destroy!
        return render json: nil, status: :no_content
      end
    end
    render json: nil, status: :not_found
  end

end
