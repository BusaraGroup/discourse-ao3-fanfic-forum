# frozen_string_literal: true

module Ao3FanficForum
  class CryptoPaymentsController < BaseController
    requires_plugin PLUGIN_NAME
    requires_login

    def create
      RateLimiter.new(current_user, "ao3-crypto-payment", 5, 1.hour).performed!

      data = payment_data
      method = SupporterAccess.crypto_payment_method(data[:currency])

      if method.blank?
        flash[:error] = I18n.t("ao3_fanfic.crypto_payment.flash.unavailable")
        return redirect_to supporter_payment_url
      end

      post = create_staff_message(method, data)
      flash[post.present? ? :notice : :error] = if post.present?
        I18n.t("ao3_fanfic.crypto_payment.flash.submitted")
      else
        I18n.t("ao3_fanfic.crypto_payment.flash.failed")
      end

      redirect_to supporter_payment_url
    rescue ActionController::ParameterMissing, Discourse::InvalidParameters => e
      flash[:error] = e.message
      redirect_to supporter_payment_url
    end

    private

    def payment_data
      permitted = params.require(:crypto_payment).permit(:currency, :transaction_id, :amount_note)

      transaction_id = Normalizer.text(permitted[:transaction_id], max_length: 200)
      if transaction_id.blank?
        raise Discourse::InvalidParameters.new(
                I18n.t("ao3_fanfic.crypto_payment.errors.transaction_required"),
              )
      end

      {
        currency: Normalizer.text(permitted[:currency], max_length: 12).downcase,
        transaction_id: transaction_id,
        amount_note: Normalizer.text(permitted[:amount_note], max_length: 140),
      }
    end

    def create_staff_message(method, data)
      staff_group = Group[:staff] || Group[:admins]
      return if staff_group.blank?

      amount_note =
        data[:amount_note].presence || I18n.t("ao3_fanfic.crypto_payment.staff_message.unspecified")
      method_name = I18n.t(method[:name_key])

      creator =
        PostCreator.new(
          Discourse.system_user,
          title:
            I18n.t(
              "ao3_fanfic.crypto_payment.staff_message.title",
              username: current_user.username,
              code: method[:code],
            ),
          raw:
            I18n.t(
              "ao3_fanfic.crypto_payment.staff_message.body",
              username: current_user.username,
              user_url: discourse_path("/u/#{current_user.username_lower}"),
              method: method_name,
              code: method[:code],
              address: method[:address],
              transaction_id: data[:transaction_id],
              amount_note: amount_note,
            ),
          archetype: Archetype.private_message,
          target_group_names: staff_group.name,
          skip_validations: true,
        )
      post = creator.create

      return if creator.errors.present?

      post
    end

    def supporter_payment_url
      discourse_path("/ao3-fanfic/supporter#payment-methods")
    end
  end
end
