module TwoFactorAuthCode
  # The WebauthnAuthenticationPresenter class is the presenter for webauthn verification
  class WebauthnAuthenticationPresenter < TwoFactorAuthCode::GenericDeliveryPresenter
    include ActionView::Helpers::TranslationHelper

    attr_reader :credential_ids, :user_opted_remember_device_cookie

    def webauthn_help
      if service_provider_mfa_policy.aal3_required? &&
           service_provider_mfa_policy.allow_user_to_switch_method?
        t('instructions.mfa.webauthn.confirm_webauthn_or_aal3_html')
      elsif service_provider_mfa_policy.aal3_required?
        t('instructions.mfa.webauthn.confirm_webauthn_only_html')
      else
        t('instructions.mfa.webauthn.confirm_webauthn_html')
      end
    end

    def help_text
      ''
    end

    def header
      ''
    end

    def link_text
      if service_provider_mfa_policy.aal3_required?
        if service_provider_mfa_policy.allow_user_to_switch_method?
          t('two_factor_authentication.webauthn_piv_available')
        else
          ''
        end
      else
        super
      end
    end

    def link_path
      if service_provider_mfa_policy.aal3_required?
        service_provider_mfa_policy.allow_user_to_switch_method? ? login_two_factor_piv_cac_url : ''
      else
        super
      end
    end

    def cancel_link
      reauthn ? account_path : sign_out_path
    end

    def fallback_question
      if service_provider_mfa_policy.allow_user_to_switch_method?
        t('two_factor_authentication.webauthn_fallback.question')
      else
        ''
      end
    end
  end
end
