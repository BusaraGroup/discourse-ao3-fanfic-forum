# frozen_string_literal: true

module Ao3FanficForum
  class BaseController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    layout "no_ember"
    skip_before_action :preload_json, :check_xhr

    private

    def discourse_path(path)
      return path if path.blank? || path.match?(%r{\A[a-z][a-z0-9+\-.]*://}i)

      base_path = Discourse.base_path
      normalized_path = path.start_with?("/") ? path : "/#{path}"
      return normalized_path if base_path.blank? || normalized_path.start_with?(base_path)

      "#{base_path}#{normalized_path}"
    end
  end
end
