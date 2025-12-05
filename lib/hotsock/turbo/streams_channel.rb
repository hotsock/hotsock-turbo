# frozen_string_literal: true

module Hotsock
  module Turbo
    class StreamsChannel
      def self.enabled?
        defined?(::Turbo::StreamsChannel)
      end

      def self.turbo_stream_action_tag(
        action,
        target: nil,
        targets: nil,
        template: nil,
        **attributes
      )
        target_attr = target ? %(target="#{ERB::Util.html_escape(target)}") : nil
        targets_attr = targets ? %(targets="#{ERB::Util.html_escape(targets)}") : nil
        attrs = [target_attr, targets_attr]
        attributes.each { |k, v| attrs << %(#{k}="#{ERB::Util.html_escape(v)}") }
        attrs_str = attrs.compact.join(" ")
        inner = template || ""
        %(<turbo-stream action="#{ERB::Util.html_escape(action)}" #{attrs_str}><template>#{inner}</template></turbo-stream>)
      end

      def self.render_broadcast_action(rendering)
        rendering = rendering.dup
        content = rendering.delete(:content)
        html = rendering.delete(:html)
        render = rendering.delete(:render)

        return nil if render == false
        return content if content
        return html if html
        return ApplicationController.render(formats: [:html], **rendering) if rendering.present?

        nil
      end

      # This is designed this way to be consistent with Action Cable.
      # We can extend this to allow for multiple channels on a single model in the future.
      def broadcasting_for(model)
        self.class.serialize_broadcasting(model)
      end

      def self.broadcast_action_to(
        *streamables,
        action:,
        target: nil,
        targets: nil,
        attributes: {},
        timestamp: nil,
        **rendering
      )
        timestamp ||= Time.current.to_f
        attributes = attributes.merge(timestamp: timestamp)

        options = {
          action: :"#{target}_#{action}",
          timestamp: timestamp
        }

        broadcast_to(
          *streamables,
          turbo_stream_action_tag(
            action,
            target: target,
            targets: targets,
            template: render_broadcast_action(rendering),
            **attributes
          ),
          options
        )
      end

      def self.broadcast_to(stream_or_streamable, content, options = {})
        unless enabled?
          fail "Turbo Streams is not enabled. Please install turbo-rails to use this method."
        end

        channel = serialize_broadcasting(stream_or_streamable)
        event = "turbo_stream"
        data = {
          html: content,
          action: options[:action],
          timestamp: options[:timestamp]
        }.compact

        Hotsock.publish_message(channel:, event:, data:)
      end

      def self.broadcast_append_to(stream, target:, partial:, locals: {}, timestamp: nil)
        broadcast_action_to(
          stream,
          action: :append,
          target: target,
          partial: partial,
          locals: locals,
          timestamp: timestamp
        )
      end

      def self.broadcast_replace_to(stream, target:, partial:, locals: {}, timestamp: nil)
        broadcast_action_to(
          stream,
          action: :replace,
          target: target,
          partial: partial,
          locals: locals,
          timestamp: timestamp
        )
      end

      def self.broadcast_prepend_to(stream, target:, partial:, locals: {}, timestamp: nil)
        broadcast_action_to(
          stream,
          action: :prepend,
          target: target,
          partial: partial,
          locals: locals,
          timestamp: timestamp
        )
      end

      def self.broadcast_remove_to(stream, target:)
        html =
          %(<turbo-stream action="remove" target="#{ERB::Util.html_escape(target)}"></turbo-stream>)
        broadcast_to(stream, html)
      end

      def self.broadcast_update_to(stream, target:, partial:, locals: {}, timestamp: nil)
        broadcast_action_to(
          stream,
          action: :update,
          target: target,
          partial: partial,
          locals: locals,
          timestamp: timestamp
        )
      end

      # Convert the method to a class method to be used by both instance and class methods
      def self.serialize_broadcasting(streamable)
        if streamable.is_a?(String)
          streamable
        elsif streamable.is_a?(Array)
          streamable.map { |s| serialize_broadcasting(s) }.join(",")
        elsif streamable.respond_to?(:to_gid_param)
          streamable.to_gid_param
        elsif streamable.respond_to?(:to_param)
          streamable.to_param
        else
          fail ArgumentError, "Invalid streamable object: #{streamable.inspect}"
        end
      end
    end
  end
end
