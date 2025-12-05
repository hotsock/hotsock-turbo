# frozen_string_literal: true

$LOAD_PATH.unshift(::File.join(::File.dirname(__FILE__), "lib"))

require "hotsock/turbo/version"

Gem::Specification.new do |spec|
  spec.name = "hotsock-turbo"
  spec.version = Hotsock::Turbo::VERSION
  spec.authors = ["James Miller"]
  spec.email = ["support@hotsock.io"]
  spec.homepage = "https://www.hotsock.io"
  spec.summary = "Turbo Streams integration for Hotsock"
  spec.description = "Provides Turbo Streams integration for Hotsock, enabling real-time updates in Rails applications using Hotsock's WebSocket infrastructure."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata = {
    "homepage_uri" => "https://www.hotsock.io",
    "bug_tracker_uri" => "https://github.com/hotsock/hotsock-turbo/issues",
    "documentation_uri" => "https://github.com/hotsock/hotsock-turbo/blob/main/README.md",
    "changelog_uri" => "https://github.com/hotsock/hotsock-turbo/releases",
    "source_code_uri" => "https://github.com/hotsock/hotsock-turbo"
  }

  ignored = Regexp.union(
    /\A\.git/,
    /\Atest/
  )
  spec.files = `git ls-files`.split("\n").reject { |f| ignored.match(f) }

  spec.add_dependency "hotsock", ">= 1.0"
end
