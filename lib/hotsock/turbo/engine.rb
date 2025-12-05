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
    end
  end
end
