# frozen_string_literal: true

module Ao3FanficForum
  class RoomRequestsController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    requires_login

    def create
      category = private_rooms_category

      if category.blank?
        return render_json_error(
                 I18n.t("ao3_fanfic.room_requests.errors.category_missing"),
                 status: :bad_request,
               )
      end

      if !current_user.staff? && !supporter_group_member?
        return render json: {
                        errors: [
                          I18n.t("ao3_fanfic.room_requests.errors.supporter_required"),
                        ],
                        subscribe_url: SiteSetting.ao3_fanfic_subscribe_url,
                      },
                      status: :forbidden
      end

      data = request_data

      if data[:fandom].blank?
        return render_json_error(
                 I18n.t("ao3_fanfic.room_requests.errors.fandom_required"),
                 status: :bad_request,
               )
      end

      guardian.ensure_can_create_topic_on_category!(category.id)

      post =
        PostCreator.create!(
          current_user,
          title: request_title(data),
          raw: request_body(data),
          category: category.id,
        )

      render json: {
               success: true,
               topic_id: post.topic_id,
               topic_url: post.topic.relative_url,
             },
             status: :created
    rescue ActionController::ParameterMissing => e
      render_json_error(e.message, status: :bad_request)
    rescue Discourse::InvalidParameters => e
      render_json_error(e.message, status: :bad_request)
    end

    private

    def private_rooms_category
      slug =
        SiteSetting.ao3_fanfic_private_rooms_category_slug.presence || "private-fandom-rooms"
      Category.find_by(slug: slug)
    end

    def supporter_group_member?
      group_name =
        SiteSetting.ao3_fanfic_supporter_group_name.presence || "ao3chat_supporters"
      group = Group.find_by(name: group_name)
      group.present? &&
        GroupUser.exists?(group_id: group.id, user_id: current_user.id)
    end

    def permitted_request
      params
        .require(:room_request)
        .permit(:fandom, :ship, :purpose, :spoiler_policy, :comfort_notes)
    end

    def request_data
      {
        fandom: Normalizer.text(permitted_request[:fandom], max_length: 120),
        ship: Normalizer.text(permitted_request[:ship], max_length: 120),
        purpose: Normalizer.text(permitted_request[:purpose], max_length: 800),
        spoiler_policy:
          Normalizer.text(permitted_request[:spoiler_policy], max_length: 300),
        comfort_notes:
          Normalizer.text(permitted_request[:comfort_notes], max_length: 500),
      }
    end

    def request_title(data)
      key =
        if data[:ship].present?
          "ao3_fanfic.room_requests.title_with_ship"
        else
          "ao3_fanfic.room_requests.title"
        end

      Normalizer.text(
        I18n.t(key, fandom: data[:fandom], ship: data[:ship]),
        max_length: 255,
      )
    end

    def request_body(data)
      [
        "## #{I18n.t("ao3_fanfic.room_requests.body.heading")}",
        "",
        I18n.t("ao3_fanfic.room_requests.body.fandom", value: data[:fandom]),
        I18n.t(
          "ao3_fanfic.room_requests.body.ship",
          value: value_or_unspecified(data[:ship]),
        ),
        I18n.t(
          "ao3_fanfic.room_requests.body.purpose",
          value: value_or_unspecified(data[:purpose]),
        ),
        I18n.t(
          "ao3_fanfic.room_requests.body.spoiler_policy",
          value: value_or_unspecified(data[:spoiler_policy]),
        ),
        I18n.t(
          "ao3_fanfic.room_requests.body.comfort_notes",
          value: value_or_unspecified(data[:comfort_notes]),
        ),
      ].join("\n")
    end

    def value_or_unspecified(value)
      value.presence || I18n.t("ao3_fanfic.room_requests.body.unspecified")
    end
  end
end
