# frozen_string_literal: true

Ao3FanficForum::Engine.routes.draw do
  get "terms" => "terms#index"
  get "topics" => "topics#index"
  put "topics/:topic_id/metadata" => "metadata#update"
end

Discourse::Application.routes.draw { mount Ao3FanficForum::Engine, at: "ao3-fanfic" }
