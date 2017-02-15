module Verify
  class PhoneController < ApplicationController
    include IdvStepConcern
    include IdvFailureConcern

    before_action :confirm_step_needed
    before_action :confirm_step_allowed

    helper_method :idv_phone_form

    def new
      @view_model = Verify::PhoneNew.new(remaining_attempts: remaining_step_attempts)
      analytics.track_event(Analytics::IDV_PHONE_RECORD_VISIT)
    end

    def create
      result = step.submit
      analytics.track_event(Analytics::IDV_PHONE_CONFIRMATION, result.to_h)
      increment_step_attempts

      if result.success?
        redirect_to verify_review_url
      else
        render_failure
        render :new
      end
    end

    private

    def step_name
      :phone
    end

    def step
      @_step ||= Idv::PhoneStep.new(
        idv_form: idv_phone_form,
        idv_session: idv_session,
        params: step_params
      )
    end

    def view_model(error: nil)
      Verify::PhoneNew.new(error: error, remaining_attempts: remaining_step_attempts)
    end

    def step_params
      params.require(:idv_phone_form).permit(:phone)
    end

    def confirm_step_needed
      redirect_to verify_review_path if idv_session.phone_confirmation == true
    end

    def idv_phone_form
      @_idv_phone_form ||= Idv::PhoneForm.new(idv_session.params, current_user)
    end
  end
end
