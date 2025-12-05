# frozen_string_literal: true

require_relative "../../helper"
require "ostruct"
require "rails"
require "action_controller/railtie"
require "hotsock/turbo/engine"

# Create a minimal Rails application to run the engine initializers
unless defined?(TestApp)
  class TestApp < Rails::Application
    config.eager_load = false
    config.secret_key_base = "test"
    config.hosts.clear
  end
  TestApp.initialize!
end

class ApplicationController < ActionController::Base
end

describe Hotsock::Turbo::StreamsChannel do
  before do
    @stream = "test_channel"
    @partial = "tasks/task"
    @locals = {task: OpenStruct.new(id: 1, title: "Test Task")}
    @html = "<template>Task</template>"
    @remove_html = "<turbo-stream action=\"remove\" target=\"tasks-turbo-frame\"></turbo-stream>"
    @controller = ApplicationController.new
    @target = "tasks-turbo-frame"
  end

  it "broadcast_append_to" do
    inner_html = "Task"

    ActionController::Base.stub :render, inner_html do
      Hotsock::Turbo::StreamsChannel.stub :broadcast_to, ->(stream, html, options = {}) do
        assert_equal stream, @stream
        assert_match(/append/, html)
        assert_match(/tasks-turbo-frame/, html)
        assert_match(/Task/, html)
        assert_equal :"tasks-turbo-frame_append", options[:action]
        assert_kind_of Float, options[:timestamp]
      end do
        Hotsock::Turbo::StreamsChannel.broadcast_append_to(
          @stream,
          target: @target,
          partial: @partial,
          locals: @locals
        )
      end
    end
  end

  def test_broadcast_prepend_to
    inner_html = "Task"

    ActionController::Base.stub :render, inner_html do
      Hotsock::Turbo::StreamsChannel.stub :broadcast_to, ->(stream, html, options = {}) do
        assert_equal stream, @stream
        assert_match(/prepend/, html)
        assert_match(/tasks-turbo-frame/, html)
        assert_match(/Task/, html)
        assert_equal :"tasks-turbo-frame_prepend", options[:action]
        assert_kind_of Float, options[:timestamp]
      end do
        Hotsock::Turbo::StreamsChannel.broadcast_prepend_to(
          @stream,
          target: @target,
          partial: @partial,
          locals: @locals
        )
      end
    end
  end

  def test_broadcast_replace_to
    inner_html = "Task"

    ActionController::Base.stub :render, inner_html do
      Hotsock::Turbo::StreamsChannel.stub :broadcast_to, ->(stream, html, options) do
        assert_equal stream, @stream
        assert_match(/replace/, html)
        assert_match(/tasks-turbo-frame/, html)
        assert_match(/Task/, html)
        assert_equal :"tasks-turbo-frame_replace", options[:action]
        assert_kind_of Float, options[:timestamp]
      end do
        Hotsock::Turbo::StreamsChannel.broadcast_replace_to(
          @stream,
          target: @target,
          partial: @partial,
          locals: @locals
        )
      end
    end
  end

  def test_broadcast_update_to
    inner_html = "Task"

    ActionController::Base.stub :render, inner_html do
      Hotsock::Turbo::StreamsChannel.stub :broadcast_to, ->(stream, html, options = {}) do
        assert_equal stream, @stream
        assert_match(/update/, html)
        assert_match(/tasks-turbo-frame/, html)
        assert_match(/Task/, html)
        assert_equal :"tasks-turbo-frame_update", options[:action]
        assert_kind_of Float, options[:timestamp]
      end do
        Hotsock::Turbo::StreamsChannel.broadcast_update_to(
          @stream,
          target: @target,
          partial: @partial,
          locals: @locals
        )
      end
    end
  end

  def test_broadcast_remove_to
    expected_html = %(<turbo-stream action="remove" target="tasks-turbo-frame"></turbo-stream>)
    Hotsock::Turbo::StreamsChannel.stub :broadcast_to, ->(stream, html, options = {}) do
      assert_equal stream, @stream
      assert_equal expected_html, html
      assert_equal({}, options)
    end do
      Hotsock::Turbo::StreamsChannel.broadcast_remove_to(@stream, target: @target)
    end
  end

  def test_broadcast_to_with_optional_options
    html = "<turbo-stream>test</turbo-stream>"

    Hotsock::Turbo::StreamsChannel.stub :enabled?, true do
      Hotsock.stub :publish_message, ->(channel:, event:, data:) do
        assert_equal @stream, channel
        assert_equal "turbo_stream", event
        assert_equal({html:}, data)
      end do
        Hotsock::Turbo::StreamsChannel.broadcast_to(@stream, html)
      end
    end
  end
end
