# frozen_string_literal: true

module Hotsock
  module Turbo
    class Config
      attr_accessor :parent_controller

      def initialize
        @parent_controller = "ApplicationController"
      end
    end
  end
end
