# frozen_string_literal: true

module Hotsock
  module Turbo
    module StreamsHelper
      def hotsock_turbo_meta_tags(connect_token_path: nil, wss_url: nil, log_level: nil)
        config = Hotsock::Turbo.config
        tags = [
          tag(:meta, name: "hotsock:connect-token-path", content: connect_token_path || config.connect_token_path),
          tag(:meta, name: "hotsock:log-level", content: log_level || config.log_level),
          tag(:meta, name: "hotsock:wss-url", content: wss_url || config.wss_url)
        ]
        safe_join(tags, "\n")
      end

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
          channels: {channel_name => {omitFromSubCount: true, subscribe: true}},
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
        respond_to?(:hotsock_uid, true) ? hotsock_uid : session.id.to_s
      end
    end
  end
end
