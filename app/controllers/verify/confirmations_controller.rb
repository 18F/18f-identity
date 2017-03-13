module Verify
  class ConfirmationsController < ApplicationController
    include IdvSession

    before_action :confirm_two_factor_authenticated
    before_action :confirm_idv_vendor_session_started
    before_action :confirm_profile_has_been_created

    def show
      track_final_idv_event

      finish_proofing_success
    end

    def update
      redirect_to next_step
    end

    private

    def next_step
      if session[:sp]
        sign_up_completed_path
      else
        after_sign_in_path_for(current_user)
      end
    end

    def confirm_profile_has_been_created
      redirect_to profile_path unless idv_session.profile.present?
    end

    def track_final_idv_event
      result = {
        success: true,
        new_phone_added: idv_session.params['phone_confirmed_at'].present?,
      }
      analytics.track_event(Analytics::IDV_FINAL, result)
    end

    def finish_proofing_success
      @recovery_code = recovery_code
      idv_session.complete_profile
      idv_session.recovery_code = nil
      flash[:allow_confirmations_continue] = true
      flash.now[:success] = t('idv.messages.confirm')
    end

    def recovery_code
      idv_session.recovery_code || generate_recovery_code
    end

    def generate_recovery_code
      cacher = Pii::Cacher.new(current_user, user_session)
      idv_session.profile.encrypt_recovery_pii(cacher.fetch)
    end
  end
end
