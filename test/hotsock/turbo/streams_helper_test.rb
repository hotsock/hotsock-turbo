# frozen_string_literal: true

require_relative "../../helper"
require "ostruct"
require "rails"
require "action_controller/railtie"
require "hotsock/turbo/engine"

unless defined?(TestApp)
  class TestApp < Rails::Application
    config.eager_load = false
    config.secret_key_base = "test"
    config.hosts.clear
  end
  TestApp.initialize!
end

class DummyController < ActionController::Base
  include ActionView::Helpers::TagHelper
  include Hotsock::Turbo::StreamsHelper

  class_attribute :test_uid, default: nil

  def view_context
    self
  end

  def hotsock_uid
    self.class.test_uid || ""
  end
end

describe Hotsock::Turbo::StreamsHelper do
  before do
    @controller = DummyController.new
    DummyController.test_uid = nil
  end

  after do
    DummyController.test_uid = nil
  end

  it "generates attributes with hotsock_uid method" do
    DummyController.test_uid = "test-user-id"
    streamables = %w[stream1 stream2]
    expected_stream_name = "stream1,stream2"

    Hotsock.stub :issue_token, "fake-token" do
      result = @controller.hotsock_turbo_stream_from(*streamables, class: "test-class")

      assert_includes result, "data-channel=\"#{expected_stream_name}\""
      assert_includes result, "data-token=\"fake-token\""
      assert_includes result, "data-user-id=\"test-user-id\""
      assert_includes result, "class=\"test-class\""
      assert_includes result, "<hotsock-turbo-stream-source"
    end
  end

  it "uses custom hotsock_uid method" do
    DummyController.test_uid = "custom-user-123"

    Hotsock.stub :issue_token, "fake-token" do
      result = @controller.hotsock_turbo_stream_from("stream")
      assert_includes result, "data-user-id=\"custom-user-123\""
    end
  end

  it "falls back to session.id when hotsock_uid not defined" do
    # Controller without hotsock_uid but with session
    controller_without_uid = Class.new(ActionController::Base) do
      include ActionView::Helpers::TagHelper
      include Hotsock::Turbo::StreamsHelper

      def view_context
        self
      end

      def session
        @session ||= OpenStruct.new(id: "fallback-session-id")
      end
    end.new

    Hotsock.stub :issue_token, "fake-token" do
      result = controller_without_uid.hotsock_turbo_stream_from("stream")
      assert_includes result, "data-user-id=\"fallback-session-id\""
    end
  end
end
