# frozen_string_literal: true

module Hotsock
  module Turbo
    class TokensController < Hotsock::Turbo.config.parent_controller.constantize
      # The client fetches a fresh connect token before every reconnect, often
      # long after the page loaded. The page's CSRF token may no longer match
      # the session by then, which would fail every reconnect until the page is
      # reloaded. Issuing a token changes nothing, and other sites can't read
      # the response, so this endpoint doesn't need forgery protection.
      skip_forgery_protection if respond_to?(:skip_forgery_protection)

      def connect
        render json: {token: connect_token}
      end

      private

      def connect_token
        uid = respond_to?(:hotsock_uid, true) ? hotsock_uid : session.id.to_s
        umd = respond_to?(:hotsock_umd, true) ? hotsock_umd : nil

        claims = {scope: "connect", keepAlive: true, uid:, umd:}
        Hotsock.issue_token(claims)
      end
    end
  end
end
