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
    @original_uid_resolver = Hotsock::Turbo.config.uid_resolver
    @original_umd_resolver = Hotsock::Turbo.config.umd_resolver

    Hotsock.configure do |config|
      config.aws_region = "us-east-1"
      config.issuer_private_key = TEST_ES256_PRIVATE_KEY_PEM
      config.issuer_key_algorithm = "ES256"
      config.issuer_token_ttl = 3600
    end
  end

  def teardown
    Hotsock.reset_config!
    Hotsock::Turbo.config.uid_resolver = @original_uid_resolver
    Hotsock::Turbo.config.umd_resolver = @original_umd_resolver
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

  def test_connect_uses_custom_uid_resolver
    Hotsock::Turbo.config.uid_resolver = ->(controller) { "custom-user-456" }

    post "/hotsock/connect"

    assert_response :success
    decoded = JWT.decode(JSON.parse(response.body)["token"], nil, false).first
    assert_equal "custom-user-456", decoded["uid"]
  end

  def test_connect_includes_umd_when_resolver_configured
    Hotsock::Turbo.config.umd_resolver = ->(controller) { {name: "Test User", role: "admin"} }

    post "/hotsock/connect"

    assert_response :success
    decoded = JWT.decode(JSON.parse(response.body)["token"], nil, false).first
    assert_equal({"name" => "Test User", "role" => "admin"}, decoded["umd"])
  end

  def test_connect_omits_umd_when_resolver_returns_nil
    Hotsock::Turbo.config.umd_resolver = ->(controller) {}

    post "/hotsock/connect"

    assert_response :success
    decoded = JWT.decode(JSON.parse(response.body)["token"], nil, false).first
    refute decoded.key?("umd")
  end

  def test_parent_controller_defaults_to_action_controller_api
    assert_equal "ActionController::API", Hotsock::Turbo.config.parent_controller
  end
end
