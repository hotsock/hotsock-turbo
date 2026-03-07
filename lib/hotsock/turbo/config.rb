# frozen_string_literal: true

module Hotsock
  module Turbo
    class Config
      attr_accessor :parent_controller, :connect_token_path, :wss_url, :lazy_connection, :override_turbo_broadcastable, :suppress_broadcasts
      attr_writer :log_level

      def initialize
        @parent_controller = "ApplicationController"
        @connect_token_path = nil
        @wss_url = nil
        @log_level = :default
        @lazy_connection = false
        @override_turbo_broadcastable = false
        @suppress_broadcasts = false
      end

      def log_level
        if @log_level == :default
          (defined?(Rails) && Rails.env.development?) ? "debug" : "warn"
        else
          @log_level
        end
      end
    end
  end
end
