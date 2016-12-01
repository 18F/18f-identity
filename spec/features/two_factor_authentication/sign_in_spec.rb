require 'rails_helper'

include Features::ActiveJobHelper

feature 'Two Factor Authentication' do
  describe 'When the user has not setup 2FA' do
    scenario 'user is prompted to setup two factor authentication at first sign in' do
      sign_in_before_2fa

      expect(current_path).to eq phone_setup_path
      expect(page).
        to have_content t('devise.two_factor_authentication.two_factor_setup')
    end

    scenario 'user does not fill out a phone number when signing up' do
      sign_up_and_set_password
      click_button t('forms.buttons.send_passcode')

      expect(current_path).to eq phone_setup_path
    end

    scenario 'user attempts to circumnavigate OTP setup' do
      sign_in_before_2fa

      visit profile_path

      expect(current_path).to eq phone_setup_path
    end

    describe 'user selects phone' do
      scenario 'user leaves phone blank' do
        sign_in_before_2fa
        fill_in 'Phone', with: ''
        click_button t('forms.buttons.send_passcode')

        expect(page).to have_content invalid_phone_message
      end

      scenario 'user enters an invalid number with no digits' do
        sign_in_before_2fa
        fill_in 'Phone', with: 'five one zero five five five four three two one'
        click_button t('forms.buttons.send_passcode')

        expect(page).to have_content invalid_phone_message
      end

      scenario 'user enters a valid number' do
        user = sign_in_before_2fa
        fill_in 'Phone', with: '555-555-1212'
        click_button t('forms.buttons.send_passcode')

        expect(page).to_not have_content invalid_phone_message
        expect(current_path).to eq login_two_factor_path(delivery_method: 'sms')
        expect(user.reload.phone).to_not eq '+1 (555) 555-1212'
      end
    end
  end

  describe 'When the user has set a preferred method' do
    describe 'Using phone' do
      context 'user is prompted for otp via phone only' do
        before do
          reset_job_queues
          @user = create(:user, :signed_up)
          reset_email
          sign_in_before_2fa(@user)
          click_button t('forms.buttons.submit.default')
        end

        it 'lets the user know they are signed in' do
          expect(page).to have_content t('devise.sessions.signed_in')
        end

        it 'asks the user to enter an OTP' do
          expect(page).
            to have_content t('devise.two_factor_authentication.header_text')
        end

        it 'does not send an OTP via email' do
          expect(last_email).to_not have_content('one-time passcode')
        end

        it 'does not allow user to bypass entering OTP' do
          visit profile_path

          expect(current_path).to eq user_two_factor_authentication_path
        end
      end
    end

    scenario 'user can resend one-time password (OTP)' do
      user = create(:user, :signed_up)
      sign_in_before_2fa(user)
      click_button t('forms.buttons.submit.default')
      click_link t('links.two_factor_authentication.resend_code')

      expect(page).to have_content(t('notices.send_code.sms'))
    end

    scenario 'user who enters OTP incorrectly 3 times is locked out for OTP validity period' do
      user = create(:user, :signed_up)
      sign_in_before_2fa(user)
      click_button t('forms.buttons.submit.default')

      3.times do
        fill_in('code', with: 'bad-code')
        click_button t('forms.buttons.submit.default')
      end

      expect(page).to have_content t('titles.account_locked')

      # let 10 minutes (otp validity period) magically pass
      user.update(second_factor_locked_at: Time.zone.now - (Devise.direct_otp_valid_for + 1.second))

      sign_in_before_2fa(user)
      click_button t('forms.buttons.submit.default')

      expect(page).to have_content t('devise.two_factor_authentication.header_text')
    end

    context 'user signs in while locked out' do
      it 'signs the user out and lets them know they are locked out' do
        user = create(:user, :signed_up)
        user.update(second_factor_locked_at: Time.zone.now - 1.minute)
        allow_any_instance_of(User).to receive(:max_login_attempts?).and_return(true)
        sign_in_before_2fa(user)

        expect(page).to have_content t('devise.two_factor_authentication.' \
                                       'max_login_attempts_reached')

        visit profile_path
        expect(current_path).to eq root_path
      end
    end
  end

  describe 'when the user is TOTP enabled' do
    it 'allows SMS and Voice fallbacks' do
      user = create(:user, :signed_up, otp_secret_key: 'foo')
      sign_in_before_2fa(user)

      click_link t('devise.two_factor_authentication.totp_fallback.sms_link_text')

      expect(current_path).to eq '/login/two-factor/sms'

      visit login_two_factor_authenticator_path

      click_link t('devise.two_factor_authentication.totp_fallback.voice_link_text')

      expect(current_path).to eq '/login/two-factor/voice'
    end
  end

  describe 'signing in via recovery code' do
    it 'displays new recovery code and redirects to profile after acknowledging' do
      user = create(:user, :signed_up)
      sign_in_before_2fa(user)

      code = RecoveryCodeGenerator.new(user).create
      click_link t('devise.two_factor_authentication.recovery_code_fallback.link')
      fill_in 'code', with: code
      click_button t('forms.buttons.submit.default')

      click_button t('forms.buttons.acknowledge_recovery_code')

      expect(current_path).to eq profile_path
    end
  end

  describe 'signing in when user does not already have recovery code' do
    # For example, when migrating users from another DB
    it 'displays recovery code and redirects to profile after acknowledging' do
      user = create(:user, :signed_up)
      user.update!(recovery_code: nil)

      sign_in_user(user)
      click_button t('forms.buttons.submit.default')
      fill_in 'code', with: user.reload.direct_otp
      click_button t('forms.buttons.submit.default')
      click_button t('forms.buttons.acknowledge_recovery_code')

      expect(current_path).to eq profile_path
    end
  end

  describe 'visiting OTP delivery and verification pages after fully authenticating' do
    it 'redirects to profile page' do
      sign_in_and_2fa_user
      visit login_two_factor_path(delivery_method: 'sms')

      expect(current_path).to eq profile_path

      visit user_two_factor_authentication_path

      expect(current_path).to eq profile_path
    end
  end
end
