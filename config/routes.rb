# frozen_string_literal: true

Ao3FanficForum::Engine.routes.draw do
  post "room-requests" => "room_requests#create"
  get "supporter" => "supporter#show"
  get "supporter-status" => "supporter_status#show"
  get "terms" => "terms#index"
  get "topics" => "topics#index"
  put "topics/:topic_id/metadata" => "metadata#update"
end

Discourse::Application.routes.draw { mount Ao3FanficForum::Engine, at: "ao3-fanfic" }
