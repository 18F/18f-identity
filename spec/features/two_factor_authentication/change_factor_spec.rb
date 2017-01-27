require 'rails_helper'

feature 'Changing authentication factor' do
  describe 'requires re-authenticating' do
    let!(:user) { sign_up_and_2fa }

    scenario 'editing password' do
      visit manage_password_path
      complete_2fa_confirmation

      expect(current_path).to eq manage_password_path
    end

    scenario 'editing phone number' do
      allow(SmsSenderNumberChangeJob).to receive(:perform_later)

      @previous_phone_confirmed_at = user.reload.phone_confirmed_at
      previous_phone = user.phone
      new_phone = '+1 (703) 555-0100'

      visit manage_phone_path
      complete_2fa_confirmation

      update_phone_number
      expect(page).to have_link t('forms.two_factor.try_again'), href: manage_phone_path
      expect(page).not_to have_content(
        t('devise.two_factor_authentication.recovery_code_fallback.text_html')
      )
      choose_sms_delivery

      expect(page).to have_link t('forms.two_factor.try_again'), href: manage_phone_path

      enter_incorrect_otp_code

      expect(page).to have_content t('devise.two_factor_authentication.invalid_otp')
      expect(user.reload.phone).to_not eq new_phone
      expect(page).to have_link t('forms.two_factor.try_again'), href: manage_phone_path

      enter_correct_otp_code_for_user(user)

      expect(page).to have_content t('notices.phone_confirmation_successful')
      expect(current_path).to eq profile_path
      expect(SmsSenderNumberChangeJob).to have_received(:perform_later).with(previous_phone)
      expect(page).to have_content new_phone
      expect(user.reload.phone_confirmed_at).to_not eq(@previous_phone_confirmed_at)

      visit login_two_factor_path(delivery_method: 'sms')
      expect(current_path).to eq profile_path
    end

    scenario 'waiting too long to change phone number' do
      allow(SmsOtpSenderJob).to receive(:perform_later)

      user = sign_in_and_2fa_user
      old_phone = user.phone
      visit manage_phone_path
      update_phone_number
      choose_sms_delivery

      Timecop.travel(Figaro.env.reauthn_window.to_i + 1) do
        click_link t('forms.two_factor.try_again'), href: manage_phone_path
        complete_2fa_confirmation_without_entering_otp

        expect(SmsOtpSenderJob).to have_received(:perform_later).
          with(
            code: user.reload.direct_otp,
            phone: old_phone,
            otp_created_at: user.reload.direct_otp_sent_at.to_s
          )

        expect(page).to have_content UserDecorator.new(user).masked_two_factor_phone_number
        expect(page).not_to have_link t('forms.two_factor.try_again')
      end
    end

    context 'resending OTP code to old phone' do
      it 'resends OTP and prompts user to enter their code' do
        allow(SmsOtpSenderJob).to receive(:perform_later)

        user = sign_in_and_2fa_user
        old_phone = user.phone

        Timecop.travel(Figaro.env.reauthn_window.to_i + 1) do
          visit manage_phone_path
          complete_2fa_confirmation_without_entering_otp
          click_link t('links.two_factor_authentication.resend_code.sms')

          expect(SmsOtpSenderJob).to have_received(:perform_later).
            with(
              code: user.reload.direct_otp,
              phone: old_phone,
              otp_created_at: user.reload.direct_otp_sent_at.to_s
            )

          expect(current_path).
            to eq login_two_factor_path(delivery_method: 'sms')
        end
      end
    end

    scenario 'editing email' do
      visit manage_email_path
      complete_2fa_confirmation

      expect(current_path).to eq manage_email_path
    end
  end

  context 'user has authenticator app enabled' do
    it 'allows them to change their email, password, or phone' do
      sign_in_with_totp_enabled_user

      Timecop.travel(Figaro.env.reauthn_window.to_i + 1) do
        visit manage_email_path
        submit_current_password_and_totp

        expect(current_path).to eq manage_email_path
      end

      Timecop.travel(Figaro.env.reauthn_window.to_i * 3) do
        visit manage_password_path
        submit_current_password_and_totp

        expect(current_path).to eq manage_password_path
      end

      Timecop.travel(Figaro.env.reauthn_window.to_i * 4) do
        visit manage_phone_path
        submit_current_password_and_totp

        expect(current_path).to eq manage_phone_path
      end
    end
  end

  def complete_2fa_confirmation
    complete_2fa_confirmation_without_entering_otp
    click_submit_default
  end

  def complete_2fa_confirmation_without_entering_otp
    expect(current_path).to eq user_password_confirm_path

    fill_in 'Password', with: Features::SessionHelper::VALID_PASSWORD
    click_button t('forms.buttons.continue')

    expect(current_path).to eq user_two_factor_authentication_path

    click_submit_default

    expect(current_path).to eq login_two_factor_path(delivery_method: 'sms')
  end

  def update_phone_number
    fill_in 'update_user_phone_form[phone]', with: '703-555-0100'
    click_button t('forms.buttons.submit.confirm_change')
  end

  def enter_incorrect_otp_code
    fill_in 'code', with: '12345'
    click_submit_default
  end

  def submit_current_password_and_totp
    fill_in 'Password', with: Features::SessionHelper::VALID_PASSWORD
    click_button t('forms.buttons.continue')

    expect(current_path).to eq login_two_factor_authenticator_path

    fill_in 'code', with: generate_totp_code(@secret)
    click_submit_default
  end

  def choose_sms_delivery
    click_submit_default
  end
end
