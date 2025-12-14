# frozen_string_literal: true

require "hotsock"
require "hotsock/turbo/version"
require "hotsock/turbo/config"
require "hotsock/turbo/streams_channel"
require "hotsock/turbo/streams_helper"
require "hotsock/turbo/broadcastable"
require "hotsock/turbo/engine" if defined?(Rails)

module Hotsock
  module Turbo
    class << self
      def configure
        yield config
      end

      def config
        @config ||= Config.new
      end
    end
  end
end
