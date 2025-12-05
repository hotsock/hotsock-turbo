# frozen_string_literal: true

module Hotsock
  module Turbo
    module StreamsHelper
      def hotsock_turbo_stream_from(*streamables, **attributes)
        channel = Hotsock::Turbo::StreamsChannel.new
        channel_name = channel.broadcasting_for(streamables)
        token = create_subscription_token(channel_name)
        set_attributes(attributes, token, channel_name)

        tag.hotsock_turbo_stream_source(**attributes)
      end

      private

      def create_subscription_token(channel_name)
        Hotsock.issue_token(
          scope: "subscribe",
          channels: {channel_name => {omitSubCount: true, subscribe: true}},
          uid:,
          exp: 1.week.from_now.to_i
        )
      end

      def set_attributes(attributes, token, channel_name)
        attributes[:"data-token"] = token
        attributes[:"data-channel"] = channel_name
        attributes[:"data-user-id"] = uid
      end

      def uid
        resolver = Hotsock::Turbo.config.uid_resolver
        resolver ? resolver.call(self) : ""
      end
    end
  end
end
