require 'rails_helper'

feature 'Email confirmation during sign up' do
  scenario 'confirms valid email and sets valid password' do
    reset_email
    email = 'test@example.com'
    sign_up_with(email)
    open_email(email)
    visit_in_email(t('mailer.confirmation_instructions.link_text'))

    expect(page).to have_content t('devise.confirmations.confirmed_but_must_set_password')
    expect(page).to have_title t('titles.confirmations.show')
    expect(page).to have_content t('forms.confirmation.show_hdr')

    fill_in 'password_form_password', with: Features::SessionHelper::VALID_PASSWORD
    click_button t('forms.buttons.submit.default')

    expect(current_url).to eq phone_setup_url
    expect(page).to_not have_content t('devise.confirmations.confirmed_but_must_set_password')
  end

  scenario 'it sets reset_requested_at to nil after password confirmation' do
    user = sign_up_and_set_password

    expect(user.reset_requested_at).to be_nil
  end

  scenario 'user cannot access users/confirmations' do
    visit user_confirmation_path

    expect(page).to have_content t('errors.messages.confirmation_invalid_token')
  end

  scenario 'user cannot submit a blank confirmation token' do
    visit "#{user_confirmation_path}?confirmation_token="

    expect(page).to have_content t('errors.messages.confirmation_invalid_token')
  end

  scenario 'user cannot submit an empty single-quoted string as a token' do
    visit "#{user_confirmation_path}?confirmation_token=''"

    expect(page).to have_content t('errors.messages.confirmation_invalid_token')
  end

  scenario 'user cannot submit an empty double-quoted string as a token' do
    visit "#{user_confirmation_path}?confirmation_token=%22%22"

    expect(page).to have_content t('errors.messages.confirmation_invalid_token')
  end

  scenario 'visitor signs up but confirms with an invalid token' do
    create(:user, :unconfirmed)
    visit '/users/confirmation?confirmation_token=invalid_token'

    expect(page).to have_content t('errors.messages.confirmation_invalid_token')
    expect(current_path).to eq user_confirmation_path
  end

  scenario 'visitor signs up but confirms with an expired token' do
    allow(Devise).to receive(:confirm_within).and_return(24.hours)
    user = create(:user, :unconfirmed)
    confirm_last_user
    user.update(confirmation_sent_at: Time.current - 2.days)

    visit user_confirmation_url(confirmation_token: @raw_confirmation_token)

    expect(current_path).to eq user_confirmation_path
    expect(page).to have_content t(
      'errors.messages.confirmation_period_expired', period: '24 hours'
    )
  end

  context 'user signs up twice without confirming email' do
    it 'sends the user the confirmation email again' do
      email = 'test@example.com'

      expect { sign_up_with(email) }.
        to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(last_email.html_part.body).to have_content(
        t('devise.mailer.confirmation_instructions.subject')
      )

      expect { sign_up_with(email) }.
        to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(last_email.html_part.body).to have_content(
        t('devise.mailer.confirmation_instructions.subject')
      )
    end
  end

  context 'user signs up and requests confirmation email again' do
    it 'sends the confirmation email again' do
      sign_up_with('test@example.com')
      click_on t('links.resend')
      fill_in :user_email, with: 'test@example.com'

      expect { click_on t('forms.buttons.resend_confirmation') }.
        to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(last_email.html_part.body).to have_content(
        t('devise.mailer.confirmation_instructions.subject')
      )
    end
  end

  context 'confirmed user is signed in and tries to confirm again' do
    it 'redirects the user to the profile' do
      sign_up_and_2fa

      visit user_confirmation_url(confirmation_token: @raw_confirmation_token)

      expect(current_url).to eq profile_url
    end
  end

  context 'confirmed user is signed out and tries to confirm again' do
    it 'redirects to sign in page with message that user is already confirmed' do
      sign_up_and_set_password

      visit destroy_user_session_url
      visit "/users/confirmation?confirmation_token=#{@raw_confirmation_token}"

      expect(page).
        to have_content t('devise.confirmations.already_confirmed', action: 'Please sign in.')
      expect(current_url).to eq new_user_session_url
    end
  end
end
