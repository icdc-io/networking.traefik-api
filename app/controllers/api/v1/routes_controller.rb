class Api::V1::RoutesController < ApplicationController

  def index
    if $location_admin
      @routes = Route.all
    else
      @routes = Route.where(:owner => @@email)
    end
    render json: @routes, status: :ok
  end

  def show
    @route = Route.find_by(:id => params[:id])
    if @route&.owner.eql?(@@email) || $location_admin
      render json: { route: @route }, status: :ok
    else
      render json: nil, status: :not_found
    end
  end

  def create
    services = params[:route].delete(:services)
    certificate_id = params[:route].delete(:certificate_id)
    #### ahrechushkin: DELETE IT AFTER FIXES ON FRONTEND
    cloudgw_id = CloudGateway.find_by(:account => $current_account).id
    params[:route][:cloud_gateway_id] = cloudgw_id
    ### END
    @route = Route.create!(
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
      )
    )
    @route.update!(:certificate_id => certificate_id) if certificate_id

    if services.count == 1
      RoutesService.create!(
        :route => @route, 
        :service => Service.find_by(:id => services.first['id']), 
        :balance_type => :loadbalancer, 
        :value => nil, 
        :name => Service.find_by(:id => services.first['id']).name
        )
    elsif services.count > 1
      name = RoutesService.generate_name
      RoutesService.create!(
        :route => @route, 
        :service => Service.find_by(:id => data['id']), 
        :balance_type => :weighted,
        :value => data['weight'], 
        :name => name
      )
    end

    render json: @route, status: :ok
  end

  def update
    services = params[:route].delete(:services)
    @route = Route.find_by(:id => params[:id])

    if @route&.owner.eql?(@@email) || $location_admin
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
      @route.update!(:certificate_id => params[:route][:certificate_id]) if params[:route][:certificate_id]
      render json: @route, status: :ok
    else
      render json: nil, status: :not_found
    end 
  end

  def destroy
    @route = Route.find_by(:id => params[:id])
    if @route&.owner.eql?(@@email) || $location_admin
      @route.destroy!
      render json: @route, status: :ok
    else
      render json: nil, status: :not_found
    end
  end

end
