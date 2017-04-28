require 'rails_helper'

feature 'verify profile with OTP' do
  let(:user) { create(:user, :signed_up) }
  let(:otp) { 'abc123' }

  before do
    create(
      :profile,
      deactivation_reason: :verification_pending,
      pii: { otp: otp, ssn: '666-66-1234', dob: '1920-01-01' },
      user: user
    )
  end

  scenario 'received OTP via USPS' do
    sign_in_live_with_2fa(user)

    expect(current_path).to eq account_path

    click_on t('account.index.verification.reactivate_button')

    expect(current_path).to eq verify_profile_path

    fill_in 'Secret code', with: otp
    click_button t('forms.verify_profile.submit')

    expect(current_path).to eq account_path
    expect(page).to_not have_content(t('account.index.verification.reactivate_button'))
  end

  xscenario 'OTP has expired' do
    # see https://github.com/18F/identity-private/issues/1108#issuecomment-293328267
  end

  scenario 'wrong OTP used' do
    sign_in_live_with_2fa(user)

    click_on t('account.index.verification.reactivate_button')

    fill_in 'Secret code', with: 'the wrong code'
    click_button t('forms.verify_profile.submit')

    expect(current_path).to eq verify_profile_path
    expect(page).to have_content(t('errors.messages.otp_incorrect'))
    expect(page.body).to_not match('the wrong code')
  end
end
