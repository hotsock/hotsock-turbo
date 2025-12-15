# frozen_string_literal: true

module Hotsock
  module Turbo
    class Config
      attr_accessor :parent_controller, :connect_token_path, :wss_url, :log_level, :override_turbo_broadcastable, :suppress_broadcasts

      def initialize
        @parent_controller = "ApplicationController"
        @connect_token_path = nil
        @wss_url = nil
        @log_level = "warn"
        @override_turbo_broadcastable = false
        @suppress_broadcasts = false
      end
    end
  end
end
