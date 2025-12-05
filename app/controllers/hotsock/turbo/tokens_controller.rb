# frozen_string_literal: true

module Hotsock
  module Turbo
    class TokensController < Hotsock::Turbo.config.parent_controller.constantize
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
