module Verify
  class ConfirmationsController < ApplicationController
    include IdvSession

    before_action :confirm_two_factor_authenticated
    before_action :confirm_idv_vendor_session_started

    def index
      track_final_idv_event

      finish_proofing_success
    end

    private

    def track_final_idv_event
      result = {
        success: true,
        new_phone_added: idv_session.params['phone_confirmed_at'].present?,
      }
      analytics.track_event(Analytics::IDV_FINAL, result)
    end

    def finish_proofing_success
      @recovery_code = idv_session.recovery_code
      idv_attempter.reset
      idv_session.complete_profile
      idv_session.clear
      flash[:allow_confirmations_continue] = true
    end
  end
end
