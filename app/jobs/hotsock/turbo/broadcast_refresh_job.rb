# frozen_string_literal: true

require "active_job"

module Hotsock
  module Turbo
    class BroadcastRefreshJob < ActiveJob::Base
      discard_on ActiveJob::DeserializationError

      def perform(stream, request_id: nil)
        Hotsock::Turbo::StreamsChannel.broadcast_refresh_to(stream, request_id:)
      end
    end
  end
end
