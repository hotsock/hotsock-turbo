# frozen_string_literal: true

require_relative "../../helper"
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

# Test controller that provides hotsock_uid
class TestApplicationController < ActionController::Base
  class_attribute :test_uid, default: nil
  class_attribute :test_umd, default: nil

  private

  def hotsock_uid
    self.class.test_uid || ""
  end

  def hotsock_umd
    self.class.test_umd
  end
end

# Override parent_controller for tests
Hotsock::Turbo.config.parent_controller = "TestApplicationController"

# Force reload of TokensController with new parent
Hotsock::Turbo.send(:remove_const, :TokensController) if Hotsock::Turbo.const_defined?(:TokensController)
load File.expand_path("../../../../app/controllers/hotsock/turbo/tokens_controller.rb", __FILE__)

# Mount the engine routes (only if not already mounted)
unless TestApp.routes.routes.any? { |r|
  begin
    r.app.app == Hotsock::Turbo::Engine
  rescue
    false
  end
}
  TestApp.routes.draw do
    mount Hotsock::Turbo::Engine => "/hotsock"
  end
end

require "action_dispatch/testing/integration"

class TokensControllerTest < ActionDispatch::IntegrationTest
  def setup
    TestApplicationController.test_uid = nil
    TestApplicationController.test_umd = nil

    Hotsock.configure do |config|
      config.aws_region = "us-east-1"
      config.issuer_private_key = TEST_ES256_PRIVATE_KEY_PEM
      config.issuer_key_algorithm = "ES256"
      config.issuer_token_ttl = 3600
    end
  end

  def teardown
    Hotsock.reset_config!
    TestApplicationController.test_uid = nil
    TestApplicationController.test_umd = nil
  end

  def app
    TestApp
  end

  def test_connect_returns_token_with_scope
    post "/hotsock/connect"

    assert_response :success
    response_json = JSON.parse(response.body)
    assert response_json["token"].present?

    decoded = JWT.decode(response_json["token"], nil, false).first
    assert_equal "connect", decoded["scope"]
    assert decoded.key?("uid")
  end

  def test_connect_uses_hotsock_uid_method
    TestApplicationController.test_uid = "custom-user-456"

    post "/hotsock/connect"

    assert_response :success
    decoded = JWT.decode(JSON.parse(response.body)["token"], nil, false).first
    assert_equal "custom-user-456", decoded["uid"]
  end

  def test_connect_includes_umd_when_hotsock_umd_defined
    TestApplicationController.test_umd = {name: "Test User", role: "admin"}

    post "/hotsock/connect"

    assert_response :success
    decoded = JWT.decode(JSON.parse(response.body)["token"], nil, false).first
    assert_equal({"name" => "Test User", "role" => "admin"}, decoded["umd"])
  end

  def test_connect_includes_nil_umd_when_hotsock_umd_returns_nil
    TestApplicationController.test_umd = nil

    post "/hotsock/connect"

    assert_response :success
    decoded = JWT.decode(JSON.parse(response.body)["token"], nil, false).first
    assert_nil decoded["umd"]
  end

  def test_parent_controller_defaults_to_application_controller
    # Reset to check default (need fresh config)
    original = Hotsock::Turbo.config.parent_controller
    Hotsock::Turbo.instance_variable_set(:@config, nil)
    assert_equal "ApplicationController", Hotsock::Turbo.config.parent_controller
    Hotsock::Turbo.config.parent_controller = original
  end
end
