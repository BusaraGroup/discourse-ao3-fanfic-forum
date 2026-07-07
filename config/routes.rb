# frozen_string_literal: true

Ao3FanficForum::Engine.routes.draw do
  get "account" => "account#show"
  post "crypto-payments" => "crypto_payments#create"
  get "login" => "login#show"
  post "logout" => "logout#create"
  post "room-requests" => "room_requests#create"
  get "signup" => "signup#show"
  get "supporter" => "supporter#show"
  get "supporter-status" => "supporter_status#show"
  get "terms" => "terms#index"
  get "topics" => "topics#index"
  put "topics/:topic_id/metadata" => "metadata#update"
end

ao3_fanfic_login_path = "#{Discourse.base_path}/ao3-fanfic/login"
ao3_fanfic_signup_path = "#{Discourse.base_path}/ao3-fanfic/signup"

Discourse::Application.routes.prepend do
  get "ao3-fanfic/advanced-login" => "static#show", id: "login"
  get "login" => redirect(ao3_fanfic_login_path)
  get "signup" => redirect(ao3_fanfic_signup_path)
  mount Ao3FanficForum::Engine, at: "ao3-fanfic"
end
