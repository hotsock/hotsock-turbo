# frozen_string_literal: true

require "active_job"

module Hotsock
  module Turbo
    # The job that powers all the broadcast_$action_later broadcasts.
    class ActionBroadcastJob < ActiveJob::Base
      discard_on ActiveJob::DeserializationError

      def perform(stream, action:, target:, targets: nil, attributes: {}, **rendering)
        Hotsock::Turbo::StreamsChannel.broadcast_action_to(
          stream,
          action:,
          target:,
          targets:,
          attributes:,
          **rendering
        )
      end
    end
  end
end
