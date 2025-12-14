# frozen_string_literal: true

module Hotsock
  module Turbo
    class Engine < Rails::Engine
      isolate_namespace Hotsock::Turbo

      initializer "hotsock.turbo.helpers" do
        ActiveSupport.on_load(:action_view) do
          include Hotsock::Turbo::StreamsHelper
        end
      end

      initializer "hotsock.turbo.assets.precompile" do |app|
        if app.config.respond_to?(:assets)
          app.config.assets.precompile += %w[hotsock-turbo.js]
        end
      end

      initializer "hotsock.turbo.broadcastable" do
        ActiveSupport.on_load(:active_record) do
          include Hotsock::Turbo::Broadcastable

          if Hotsock::Turbo.config.turbo_broadcastable_override
            # Use prepend so our methods take precedence over Turbo::Broadcastable
            # (which may be included later by turbo-rails)
            prepend Hotsock::Turbo::Broadcastable::TurboBroadcastableOverride
          end
        end
      end
    end
  end
end
