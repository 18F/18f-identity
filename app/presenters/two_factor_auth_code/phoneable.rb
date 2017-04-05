module TwoFactorAuthCode
  module Phoneable
    def phone_fallback_link
      fallback_method = if otp_delivery_preference == 'voice'
                          'sms'
                        elsif otp_delivery_preference == 'sms'
                          'voice'
                        end

      t(fallback_instructions(otp_delivery_preference),
        link: phone_link_tag(fallback_method))
    end

    def update_phone_link
      return unless unconfirmed_phone

      link = link_to(t('forms.two_factor.try_again'), reenter_phone_number_path)
      t('instructions.2fa.wrong_number_html', link: link)
    end

    def phone_number_tag
      content_tag(:strong, phone_number)
    end

    def resend_code_path
      otp_send_path(
        otp_delivery_selection_form: {
          otp_delivery_preference: otp_delivery_preference, resend: true
        }
      )
    end

    private

    def fallback_instructions(method)
      "instructions.2fa.#{method}.fallback_html"
    end

    def phone_link_tag(otp_delivery_preference)
      send_path = otp_send_path(
        otp_delivery_selection_form: { otp_delivery_preference: otp_delivery_preference }
      )
      link_to(t("links.two_factor_authentication.#{otp_delivery_preference}"), send_path)
    end
  end
end
