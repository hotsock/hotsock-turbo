# frozen_string_literal: true

module Hotsock
  module Turbo
    module StreamsHelper
      def hotsock_turbo_meta_tags(connect_token_path: nil, wss_url: nil, log_level: nil, lazy_connection: nil)
        config = Hotsock::Turbo.config
        lazy = lazy_connection.nil? ? config.lazy_connection : lazy_connection
        resolved_log_level = resolve_log_level(log_level, config)
        tags = [
          tag(:meta, name: "hotsock:connect-token-path", content: connect_token_path || config.connect_token_path),
          (tag(:meta, name: "hotsock:lazy-connection", content: "true") if lazy),
          (tag(:meta, name: "hotsock:log-level", content: resolved_log_level) if resolved_log_level),
          tag(:meta, name: "hotsock:wss-url", content: wss_url || config.wss_url)
        ].compact
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

      def resolve_log_level(override, config)
        return override if override
        level = config.log_level
        return nil if level.nil?
        return(Rails.env.development? ? "debug" : "warn") if level == :default
        level
      end

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
