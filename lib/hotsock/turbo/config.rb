# frozen_string_literal: true

module Hotsock
  module Turbo
    class Config
      attr_accessor :parent_controller, :connect_token_path, :wss_url, :log_level

      def initialize
        @parent_controller = "ApplicationController"
        @connect_token_path = nil
        @wss_url = nil
        @log_level = "warn"
      end
    end
  end
end
