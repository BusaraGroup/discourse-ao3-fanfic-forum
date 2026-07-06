# frozen_string_literal: true

module Ao3FanficForum
  module SupporterAccess
    module_function

    def group_name
      SiteSetting.ao3_fanfic_supporter_group_name.presence || "ao3chat_supporters"
    end

    def supporter_group
      Group.find_by(name: group_name)
    end

    def supporter?(user)
      group = supporter_group
      user.present? && group.present? && GroupUser.exists?(group: group, user: user)
    end

    def private_room_access?(user)
      user&.staff? || supporter?(user)
    end

    def private_rooms_category
      slug =
        SiteSetting.ao3_fanfic_private_rooms_category_slug.presence || "private-fandom-rooms"
      Category.find_by(slug: slug)
    end

    def subscribe_url
      SiteSetting.ao3_fanfic_subscribe_url.presence || "/s"
    end

    def status_for(user)
      {
        signed_in: user.present?,
        supporter: supporter?(user),
        staff: user&.staff? || false,
        has_private_room_access: private_room_access?(user),
        supporter_group_name: group_name,
        subscribe_url: subscribe_url,
        private_rooms_url: private_room_url_for(user),
      }
    end

    def private_room_url_for(user)
      return if !private_room_access?(user)

      private_rooms_category&.url
    end
  end
end
