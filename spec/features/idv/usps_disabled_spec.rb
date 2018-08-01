require 'rails_helper'

feature 'disabling USPS address verification', :idv_job do
  include IdvStepHelper

  context 'with USPS address verification disabled' do
    before do
      allow(Figaro.env).to receive(:enable_usps_verification).and_return('false')
      # Whether USPS is available affects the routes that are available
      # We want path helpers for unavailable routes to raise and fail the tests
      # so we reload the routes here
      Rails.application.reload_routes!
    end

    after do
      allow(Figaro.env).to receive(:enable_usps_verification).and_call_original
      Rails.application.reload_routes!
    end

    it 'allows verification without the option to confirm address with usps' do
      user = user_with_2fa
      start_idv_from_sp
      complete_idv_steps_before_phone_step(user)

      # Link to the USPS flow should not be visible
      expect(page).to_not have_content(t('idv.form.activate_by_mail'))

      fill_out_phone_form_ok('2342255432')
      click_idv_continue

      # Link to the USPS flow should not be visible
      expect(page).to_not have_content(t('idv.form.activate_by_mail'))

      choose_idv_otp_delivery_method_sms
      enter_correct_otp_code_for_user(user)
      fill_in 'Password', with: user.password
      click_continue
      click_acknowledge_personal_key

      expect(page).to have_current_path(sign_up_completed_path)
    end
  end
end
