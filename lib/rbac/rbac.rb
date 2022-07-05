# frozen_string_literal: true

# RBAC filtration module for model classes
module Rbac
  def self.included(base)
    base.send :include, Object
    base.extend List
  end

  # Helper module for RBAC
  module Params
    def get_params(params = {})
      @@rbac_account = params[:account] || $current_account      # rubocop:disable Style/ClassVars
      @@rbac_owner   = params[:owner]   || $email                # rubocop:disable Style/ClassVars
      @role          = params[:role]    || $role

      @admin_only          = params[:admin_only]
      @location_admin_only = params[:location_admin_only]
    end

    def match_account?
      account == @@rbac_account
    end

    def match_owner?
      account == @@rbac_account && owner == @@rbac_owner
    end

    def accessible?
      case @role
      when :location_admin
        true
      when :admin
        !@admin_only
      when :member
        !@admin_only && !@location_admin_only
      end
    end
  end

  # Defines class method, RBAC filtering the list of objects
  module List
    include Params
    def filtered_list(params = {})
      get_params(params)
      return [] unless accessible?

      case @role
      when :location_admin
        all
      when :admin
        select(&:match_account?)
      when :member
        if params[:no_owner]
          select(&:match_account?)
        else
          select(&:match_owner?)
        end
      end
    end
  end

  # Defines instance method for RBAC filtration
  module Object
    include Params
    def rbac(params = {})
      get_params(params)
      return nil unless accessible?

      case @role
      when :location_admin
        self
      when :admin
        self if match_account?
      when :member
        if params[:no_owner]
          self if match_account?
        elsif match_owner?
          self
        end
      end
    end
  end
end
