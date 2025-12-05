# frozen_string_literal: true

require "bundler/setup"
Bundler.require(:default, :test)

require "maxitest/autorun"

TEST_ES256_PRIVATE_KEY_PEM = "-----BEGIN EC PRIVATE KEY-----\nMIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQg72ab3fXPvtD2iIQQ\n/RWiZh8WA6T9u6JNhEuy1DPSFpuhRANCAASmEDhCts7/LkmooXH1tMhyh9Qn94e3\ny3e/UtmnnAYMPwro8iySvqEUrYaDUqQ3iMjYpf+mvxOFmCy97MsBj/pu\n-----END EC PRIVATE KEY-----"

Aws.config[:lambda] = {
  stub_responses: {
    invoke: {
      payload: StringIO.new('{"id":null}')
    }
  }
}

module Hotsock
  def self.reset_config!
    remove_instance_variable(:@default_config) if instance_variable_defined?(:@default_config)
    remove_instance_variable(:@default_issuer) if instance_variable_defined?(:@default_issuer)
    remove_instance_variable(:@default_publisher) if instance_variable_defined?(:@default_publisher)
  end
end

module Hotsock
  module Turbo
    def self.reset_config!
      remove_instance_variable(:@config) if instance_variable_defined?(:@config)
    end
  end
end
