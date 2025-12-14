# frozen_string_literal: true

require "active_support/concern"

module Hotsock
  module Turbo
    # Provides broadcast functionality for ActiveRecord models.
    # Include this module to gain access to hotsock_broadcast methods
    # that mirror turbo-rails' broadcast methods but use Hotsock for delivery.
    #
    # Example usage:
    #
    #   class Board < ApplicationRecord
    #     hotsock_broadcasts_refreshes
    #   end
    #
    #   class Column < ApplicationRecord
    #     belongs_to :board
    #     hotsock_broadcasts_refreshes_to :board
    #   end
    #
    #   class Message < ApplicationRecord
    #     belongs_to :board
    #     hotsock_broadcasts_to :board
    #   end
    #
    module Broadcastable
      extend ActiveSupport::Concern

      included do
        thread_mattr_accessor :suppressed_turbo_broadcasts, instance_accessor: false
        delegate :suppressed_turbo_broadcasts?, to: "self.class"
      end

      module ClassMethods
        # Configures the model to broadcast creates, updates, and destroys to a stream name
        # derived at runtime by the +stream+ symbol invocation.
        def hotsock_broadcasts_to(stream, inserts_by: :append, target: hotsock_broadcast_target_default, **rendering)
          after_create_commit -> {
            hotsock_broadcast_action_later_to(
              stream.try(:call, self) || send(stream),
              action: inserts_by,
              target: target.try(:call, self) || target,
              **rendering
            )
          }
          after_update_commit -> { hotsock_broadcast_replace_later_to(stream.try(:call, self) || send(stream), **rendering) }
          after_destroy_commit -> { hotsock_broadcast_remove_to(stream.try(:call, self) || send(stream)) }
        end

        # Same as +hotsock_broadcasts_to+, but the designated stream for updates and destroys
        # is automatically set to the current model, for creates - to the model plural name.
        def hotsock_broadcasts(stream = model_name.plural, inserts_by: :append, target: hotsock_broadcast_target_default, **rendering)
          after_create_commit -> {
            hotsock_broadcast_action_later_to(stream, action: inserts_by, target: target.try(:call, self) || target, **rendering)
          }
          after_update_commit -> { hotsock_broadcast_replace_later(**rendering) }
          after_destroy_commit -> { hotsock_broadcast_remove }
        end

        # Configures the model to broadcast a "page refresh" on creates, updates, and destroys
        # to a stream name derived at runtime by the +stream+ symbol invocation.
        def hotsock_broadcasts_refreshes_to(stream)
          after_commit -> { hotsock_broadcast_refresh_later_to(stream.try(:call, self) || send(stream)) }
        end

        # Same as +hotsock_broadcasts_refreshes_to+, but the designated stream for page refreshes
        # is automatically set to the model plural name, which can be overridden by passing +stream+.
        # Uses async for create/update and sync for destroy (matching turbo-rails behavior).
        def hotsock_broadcasts_refreshes(stream = model_name.plural)
          after_create_commit -> { hotsock_broadcast_refresh_later_to(stream) }
          after_update_commit -> { hotsock_broadcast_refresh_later }
          after_destroy_commit -> { hotsock_broadcast_refresh }
        end

        # All default targets will use the return of this method.
        def hotsock_broadcast_target_default
          model_name.plural
        end

        # Executes +block+ preventing both synchronous and asynchronous broadcasts from this model.
        def suppressing_turbo_broadcasts(&block)
          original, self.suppressed_turbo_broadcasts = suppressed_turbo_broadcasts, true
          yield
        ensure
          self.suppressed_turbo_broadcasts = original
        end

        def suppressed_turbo_broadcasts?
          suppressed_turbo_broadcasts
        end
      end

      # ==================
      # Sync methods
      # ==================

      def hotsock_broadcast_remove_to(*streamables, target: self, **rendering)
        unless suppressed_turbo_broadcasts?
          Hotsock::Turbo::StreamsChannel.broadcast_remove_to(
            *streamables,
            target: hotsock_extract_target(target)
          )
        end
      end

      def hotsock_broadcast_remove(**rendering)
        hotsock_broadcast_remove_to(self, **rendering)
      end

      def hotsock_broadcast_replace_to(*streamables, **rendering)
        unless suppressed_turbo_broadcasts?
          Hotsock::Turbo::StreamsChannel.broadcast_action_to(
            *streamables,
            action: :replace,
            **hotsock_broadcast_rendering_with_defaults(rendering)
          )
        end
      end

      def hotsock_broadcast_replace(**rendering)
        hotsock_broadcast_replace_to(self, **rendering)
      end

      def hotsock_broadcast_update_to(*streamables, **rendering)
        unless suppressed_turbo_broadcasts?
          Hotsock::Turbo::StreamsChannel.broadcast_action_to(
            *streamables,
            action: :update,
            **hotsock_broadcast_rendering_with_defaults(rendering)
          )
        end
      end

      def hotsock_broadcast_update(**rendering)
        hotsock_broadcast_update_to(self, **rendering)
      end

      def hotsock_broadcast_before_to(*streamables, target: nil, targets: nil, **rendering)
        raise ArgumentError, "at least one of target or targets is required" unless target || targets
        return if suppressed_turbo_broadcasts?

        Hotsock::Turbo::StreamsChannel.broadcast_action_to(
          *streamables,
          action: :before,
          target:,
          targets:,
          **hotsock_broadcast_rendering_with_defaults(rendering, target: nil)
        )
      end

      def hotsock_broadcast_after_to(*streamables, target: nil, targets: nil, **rendering)
        raise ArgumentError, "at least one of target or targets is required" unless target || targets
        return if suppressed_turbo_broadcasts?

        Hotsock::Turbo::StreamsChannel.broadcast_action_to(
          *streamables,
          action: :after,
          target:,
          targets:,
          **hotsock_broadcast_rendering_with_defaults(rendering, target: nil)
        )
      end

      def hotsock_broadcast_append_to(*streamables, target: hotsock_broadcast_target_default, **rendering)
        unless suppressed_turbo_broadcasts?
          Hotsock::Turbo::StreamsChannel.broadcast_action_to(
            *streamables,
            action: :append,
            **hotsock_broadcast_rendering_with_defaults(rendering, target: target)
          )
        end
      end

      def hotsock_broadcast_append(target: hotsock_broadcast_target_default, **rendering)
        hotsock_broadcast_append_to(self, target: target, **rendering)
      end

      def hotsock_broadcast_prepend_to(*streamables, target: hotsock_broadcast_target_default, **rendering)
        unless suppressed_turbo_broadcasts?
          Hotsock::Turbo::StreamsChannel.broadcast_action_to(
            *streamables,
            action: :prepend,
            **hotsock_broadcast_rendering_with_defaults(rendering, target: target)
          )
        end
      end

      def hotsock_broadcast_prepend(target: hotsock_broadcast_target_default, **rendering)
        hotsock_broadcast_prepend_to(self, target: target, **rendering)
      end

      def hotsock_broadcast_refresh_to(*streamables, **attributes)
        Hotsock::Turbo::StreamsChannel.broadcast_refresh_to(*streamables, **attributes) unless suppressed_turbo_broadcasts?
      end

      def hotsock_broadcast_refresh
        hotsock_broadcast_refresh_to(self)
      end

      def hotsock_broadcast_action_to(*streamables, action:, target: hotsock_broadcast_target_default, attributes: {}, **rendering)
        unless suppressed_turbo_broadcasts?
          Hotsock::Turbo::StreamsChannel.broadcast_action_to(
            *streamables,
            action:,
            attributes:,
            **hotsock_broadcast_rendering_with_defaults(rendering, target: target)
          )
        end
      end

      def hotsock_broadcast_action(action, target: hotsock_broadcast_target_default, attributes: {}, **rendering)
        hotsock_broadcast_action_to(self, action:, target:, attributes:, **rendering)
      end

      def hotsock_broadcast_render_to(*streamables, **rendering)
        unless suppressed_turbo_broadcasts?
          Hotsock::Turbo::StreamsChannel.broadcast_render_to(
            *streamables,
            **hotsock_broadcast_rendering_with_defaults(rendering)
          )
        end
      end

      def hotsock_broadcast_render(**rendering)
        hotsock_broadcast_render_to(self, **rendering)
      end

      # ==================
      # Async methods
      # ==================

      def hotsock_broadcast_replace_later_to(*streamables, **rendering)
        unless suppressed_turbo_broadcasts?
          Hotsock::Turbo::StreamsChannel.broadcast_replace_later_to(
            *streamables,
            **hotsock_broadcast_rendering_with_defaults(rendering)
          )
        end
      end

      def hotsock_broadcast_replace_later(**rendering)
        hotsock_broadcast_replace_later_to(self, **rendering)
      end

      def hotsock_broadcast_update_later_to(*streamables, **rendering)
        unless suppressed_turbo_broadcasts?
          Hotsock::Turbo::StreamsChannel.broadcast_update_later_to(
            *streamables,
            **hotsock_broadcast_rendering_with_defaults(rendering)
          )
        end
      end

      def hotsock_broadcast_update_later(**rendering)
        hotsock_broadcast_update_later_to(self, **rendering)
      end

      def hotsock_broadcast_append_later_to(*streamables, target: hotsock_broadcast_target_default, **rendering)
        unless suppressed_turbo_broadcasts?
          Hotsock::Turbo::StreamsChannel.broadcast_append_later_to(
            *streamables,
            **hotsock_broadcast_rendering_with_defaults(rendering, target:)
          )
        end
      end

      def hotsock_broadcast_append_later(target: hotsock_broadcast_target_default, **rendering)
        hotsock_broadcast_append_later_to(self, target:, **rendering)
      end

      def hotsock_broadcast_prepend_later_to(*streamables, target: hotsock_broadcast_target_default, **rendering)
        unless suppressed_turbo_broadcasts?
          Hotsock::Turbo::StreamsChannel.broadcast_prepend_later_to(
            *streamables,
            **hotsock_broadcast_rendering_with_defaults(rendering, target:)
          )
        end
      end

      def hotsock_broadcast_prepend_later(target: hotsock_broadcast_target_default, **rendering)
        hotsock_broadcast_prepend_later_to(self, target:, **rendering)
      end

      def hotsock_broadcast_refresh_later_to(*streamables, **attributes)
        unless suppressed_turbo_broadcasts?
          Hotsock::Turbo::StreamsChannel.broadcast_refresh_later_to(
            *streamables,
            request_id: hotsock_turbo_current_request_id,
            **attributes
          )
        end
      end

      def hotsock_broadcast_refresh_later
        hotsock_broadcast_refresh_later_to(self)
      end

      def hotsock_broadcast_action_later_to(*streamables, action:, target: hotsock_broadcast_target_default, attributes: {}, **rendering)
        unless suppressed_turbo_broadcasts?
          Hotsock::Turbo::StreamsChannel.broadcast_action_later_to(
            *streamables,
            action:,
            attributes:,
            **hotsock_broadcast_rendering_with_defaults(rendering, target:)
          )
        end
      end

      def hotsock_broadcast_action_later(action:, target: hotsock_broadcast_target_default, attributes: {}, **rendering)
        hotsock_broadcast_action_later_to(self, action:, target:, attributes: attributes, **rendering)
      end

      def hotsock_broadcast_render_later_to(*streamables, **rendering)
        unless suppressed_turbo_broadcasts?
          Hotsock::Turbo::StreamsChannel.broadcast_render_later_to(
            *streamables,
            **hotsock_broadcast_rendering_with_defaults(rendering)
          )
        end
      end

      def hotsock_broadcast_render_later(**rendering)
        hotsock_broadcast_render_later_to(self, **rendering)
      end

      private

      def hotsock_broadcast_target_default
        self.class.hotsock_broadcast_target_default
      end

      def hotsock_extract_target(target)
        if target.respond_to?(:to_key)
          ActionView::RecordIdentifier.dom_id(target)
        else
          target
        end
      end

      def hotsock_broadcast_rendering_with_defaults(options, target: self)
        options = options.dup
        options[:target] = hotsock_extract_target(target) if target && !options.key?(:target) && !options.key?(:targets)
        options[:locals] = (options[:locals] || {}).reverse_merge(model_name.element.to_sym => self)
        options[:partial] ||= to_partial_path unless options[:html] || options[:template] || options[:renderable]
        options
      end

      def hotsock_turbo_current_request_id
        Turbo.current_request_id if defined?(Turbo) && Turbo.respond_to?(:current_request_id)
      end

      # Override module that aliases standard Turbo::Broadcastable method names
      # to Hotsock equivalents, enabling drop-in replacement.
      module TurboBroadcastableOverride
        extend ActiveSupport::Concern

        module ClassMethods
          def broadcasts_to(stream, inserts_by: :append, target: hotsock_broadcast_target_default, **rendering)
            hotsock_broadcasts_to(stream, inserts_by:, target:, **rendering)
          end

          def broadcasts(stream = model_name.plural, inserts_by: :append, target: hotsock_broadcast_target_default, **rendering)
            hotsock_broadcasts(stream, inserts_by:, target:, **rendering)
          end

          def broadcasts_refreshes_to(stream)
            hotsock_broadcasts_refreshes_to(stream)
          end

          def broadcasts_refreshes(stream = model_name.plural)
            hotsock_broadcasts_refreshes(stream)
          end

          def broadcast_target_default
            hotsock_broadcast_target_default
          end
        end

        # Sync instance methods
        def broadcast_remove_to(*streamables, **opts)
          hotsock_broadcast_remove_to(*streamables, **opts)
        end

        def broadcast_remove(**opts)
          hotsock_broadcast_remove(**opts)
        end

        def broadcast_replace_to(*streamables, **opts)
          hotsock_broadcast_replace_to(*streamables, **opts)
        end

        def broadcast_replace(**opts)
          hotsock_broadcast_replace(**opts)
        end

        def broadcast_update_to(*streamables, **opts)
          hotsock_broadcast_update_to(*streamables, **opts)
        end

        def broadcast_update(**opts)
          hotsock_broadcast_update(**opts)
        end

        def broadcast_before_to(*streamables, **opts)
          hotsock_broadcast_before_to(*streamables, **opts)
        end

        def broadcast_after_to(*streamables, **opts)
          hotsock_broadcast_after_to(*streamables, **opts)
        end

        def broadcast_append_to(*streamables, **opts)
          hotsock_broadcast_append_to(*streamables, **opts)
        end

        def broadcast_append(**opts)
          hotsock_broadcast_append(**opts)
        end

        def broadcast_prepend_to(*streamables, **opts)
          hotsock_broadcast_prepend_to(*streamables, **opts)
        end

        def broadcast_prepend(**opts)
          hotsock_broadcast_prepend(**opts)
        end

        def broadcast_refresh_to(*streamables, **opts)
          hotsock_broadcast_refresh_to(*streamables, **opts)
        end

        def broadcast_refresh
          hotsock_broadcast_refresh
        end

        def broadcast_action_to(*streamables, **opts)
          hotsock_broadcast_action_to(*streamables, **opts)
        end

        def broadcast_action(action, **opts)
          hotsock_broadcast_action(action, **opts)
        end

        def broadcast_render_to(*streamables, **opts)
          hotsock_broadcast_render_to(*streamables, **opts)
        end

        def broadcast_render(**opts)
          hotsock_broadcast_render(**opts)
        end

        # Async instance methods
        def broadcast_replace_later_to(*streamables, **opts)
          hotsock_broadcast_replace_later_to(*streamables, **opts)
        end

        def broadcast_replace_later(**opts)
          hotsock_broadcast_replace_later(**opts)
        end

        def broadcast_update_later_to(*streamables, **opts)
          hotsock_broadcast_update_later_to(*streamables, **opts)
        end

        def broadcast_update_later(**opts)
          hotsock_broadcast_update_later(**opts)
        end

        def broadcast_append_later_to(*streamables, **opts)
          hotsock_broadcast_append_later_to(*streamables, **opts)
        end

        def broadcast_append_later(**opts)
          hotsock_broadcast_append_later(**opts)
        end

        def broadcast_prepend_later_to(*streamables, **opts)
          hotsock_broadcast_prepend_later_to(*streamables, **opts)
        end

        def broadcast_prepend_later(**opts)
          hotsock_broadcast_prepend_later(**opts)
        end

        def broadcast_refresh_later_to(*streamables, **opts)
          hotsock_broadcast_refresh_later_to(*streamables, **opts)
        end

        def broadcast_refresh_later
          hotsock_broadcast_refresh_later
        end

        def broadcast_action_later_to(*streamables, **opts)
          hotsock_broadcast_action_later_to(*streamables, **opts)
        end

        def broadcast_action_later(**opts)
          hotsock_broadcast_action_later(**opts)
        end

        def broadcast_render_later_to(*streamables, **opts)
          hotsock_broadcast_render_later_to(*streamables, **opts)
        end

        def broadcast_render_later(**opts)
          hotsock_broadcast_render_later(**opts)
        end

        private

        def broadcast_target_default
          hotsock_broadcast_target_default
        end
      end
    end
  end
end
