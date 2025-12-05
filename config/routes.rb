# frozen_string_literal: true

Hotsock::Turbo::Engine.routes.draw do
  post "connect", to: "tokens#connect"
end
