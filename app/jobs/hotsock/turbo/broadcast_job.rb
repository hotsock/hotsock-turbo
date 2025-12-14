# frozen_string_literal: true

require "active_job"

module Hotsock
  module Turbo
    # The job that powers broadcast_render_later_to for rendering turbo stream templates.
    class BroadcastJob < ActiveJob::Base
      discard_on ActiveJob::DeserializationError

      def perform(stream, **rendering)
        Hotsock::Turbo::StreamsChannel.broadcast_render_to(stream, **rendering)
      end
    end
  end
end
