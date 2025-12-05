# frozen_string_literal: true

module Hotsock
  module Turbo
    class TokensController < Hotsock::Turbo.config.parent_controller.constantize
      def connect
        render json: {token: connect_token}
      end

      private

      def connect_token
        claims = {scope: "connect", keepAlive: true, uid: hotsock_uid}
        claims[:umd] = hotsock_umd if hotsock_umd.present?
        Hotsock.issue_token(claims)
      end

      def hotsock_uid
        resolver = Hotsock::Turbo.config.uid_resolver
        resolver ? resolver.call(self) : ""
      end

      def hotsock_umd
        Hotsock::Turbo.config.umd_resolver&.call(self)
      end
    end
  end
end
