module SignUp
  class RecoveryCodesController < ApplicationController
    include RecoveryCodeConcern

    before_action :confirm_two_factor_authenticated
    before_action :confirm_has_not_already_viewed_recovery_code, only: [:show]

    def show
      user_session.delete(:first_time_recovery_code_view)
      @code = create_new_code
      analytics.track_event(Analytics::USER_REGISTRATION_RECOVERY_CODE_VISIT)
    end

    def update
      redirect_to next_step
    end

    private

    def confirm_has_not_already_viewed_recovery_code
      return if user_session[:first_time_recovery_code_view].present?
      redirect_to after_sign_in_path_for(current_user)
    end

    def next_step
      if session[:saml_request_url]
        sign_up_completed_path
      else
        profile_path
      end
    end
  end
end
