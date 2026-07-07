# frozen_string_literal: true

Ao3FanficForum::Engine.routes.draw do
  get "account" => "account#show"
  post "crypto-payments" => "crypto_payments#create"
  get "login" => "login#show"
  post "logout" => "logout#create"
  get "password-reset" => "password_reset#show"
  post "room-requests" => "room_requests#create"
  get "signup" => "signup#show"
  get "supporter" => "supporter#show"
  get "supporter-status" => "supporter_status#show"
  get "terms" => "terms#index"
  get "topics" => "topics#index"
  put "topics/:topic_id/metadata" => "metadata#update"
end

ao3_fanfic_login_path = "#{Discourse.base_path}/ao3-fanfic/login"
ao3_fanfic_password_reset_path = "#{Discourse.base_path}/ao3-fanfic/password-reset"
ao3_fanfic_signup_path = "#{Discourse.base_path}/ao3-fanfic/signup"

Discourse::Application.routes.prepend do
  get "ao3-fanfic/account" => "ao3_fanfic_forum/account#show"
  post "ao3-fanfic/crypto-payments" => "ao3_fanfic_forum/crypto_payments#create"
  get "ao3-fanfic/advanced-login" => "static#show", id: "login"
  get "ao3-fanfic/login" => "ao3_fanfic_forum/login#show"
  post "ao3-fanfic/logout" => "ao3_fanfic_forum/logout#create"
  get "ao3-fanfic/password-reset" => "ao3_fanfic_forum/password_reset#show"
  post "ao3-fanfic/room-requests" => "ao3_fanfic_forum/room_requests#create"
  get "ao3-fanfic/signup" => "ao3_fanfic_forum/signup#show"
  get "ao3-fanfic/supporter" => "ao3_fanfic_forum/supporter#show"
  get "ao3-fanfic/supporter-status" => "ao3_fanfic_forum/supporter_status#show"
  get "ao3-fanfic/terms" => "ao3_fanfic_forum/terms#index"
  get "ao3-fanfic/topics" => "ao3_fanfic_forum/topics#index"
  put "ao3-fanfic/topics/:topic_id/metadata" => "ao3_fanfic_forum/metadata#update"
  get "login" => redirect(ao3_fanfic_login_path)
  get "password-reset" => redirect(ao3_fanfic_password_reset_path)
  get "signup" => redirect(ao3_fanfic_signup_path)
  mount Ao3FanficForum::Engine, at: "ao3-fanfic"
end
