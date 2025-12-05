# frozen_string_literal: true

module Hotsock
  module Turbo
    class Config
      attr_accessor :uid_resolver
      attr_accessor :umd_resolver
      attr_accessor :parent_controller

      def initialize
        @uid_resolver = ->(context) { context.session.id.to_s }
        @umd_resolver = nil
        @parent_controller = "ActionController::API"
      end
    end
  end
end
