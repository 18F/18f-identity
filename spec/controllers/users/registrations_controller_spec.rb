require 'rails_helper'

include Features::MailerHelper
include Features::LocalizationHelper
include Features::ActiveJobHelper

describe Users::RegistrationsController, devise: true do
  describe '#new' do
    context 'When registrations are disabled' do
      it 'prevents users from visiting sign up page' do
        allow(AppSetting).to(receive(:registrations_enabled?)).and_return(false)

        get :new

        expect(response.status).to eq(302)
        expect(response).to redirect_to root_url
      end
    end

    context 'When registrations are enabled' do
      it 'allows user to visit the sign up page' do
        allow(AppSetting).to(receive(:registrations_enabled?)).and_return(true)

        get :new

        expect(response.status).to eq(200)
        expect(response).to render_template(:new)
      end
    end

    it 'triggers completion of "demo" experiment' do
      expect(subject).to receive(:ab_finished).with(:demo)
      get :new
    end
  end

  describe '#create' do
    context 'when registering with a new email' do
      it 'tracks successful user registration' do
        stub_analytics

        allow(@analytics).to receive(:track_event)
        allow(subject).to receive(:create_user_event)

        post :create, user: { email: 'new@example.com' }

        user = User.find_with_email('new@example.com')

        analytics_hash = {
          success: true,
          errors: [],
          email_already_exists: false,
          user_id: user.uuid
        }

        expect(@analytics).to have_received(:track_event).
          with(Analytics::USER_REGISTRATION_EMAIL, analytics_hash)

        expect(subject).to have_received(:create_user_event).with(:account_created, user)
      end
    end

    it 'tracks successful user registration with existing email' do
      existing_user = create(:user)

      stub_analytics

      analytics_hash = {
        success: true,
        errors: [],
        email_already_exists: true,
        user_id: existing_user.uuid
      }

      expect(@analytics).to receive(:track_event).
        with(Analytics::USER_REGISTRATION_EMAIL, analytics_hash)
      expect(subject).to_not receive(:create_user_event)

      post :create, user: { email: existing_user.email }
    end

    it 'tracks unsuccessful user registration' do
      stub_analytics

      analytics_hash = {
        success: false,
        errors: [t('valid_email.validations.email.invalid')],
        email_already_exists: false,
        user_id: nil
      }

      expect(@analytics).to receive(:track_event).
        with(Analytics::USER_REGISTRATION_EMAIL, analytics_hash)

      post :create, user: { email: 'invalid@' }
    end
  end

  describe '#start' do
    it 'tracks page visit' do
      stub_analytics

      expect(@analytics).to receive(:track_event).
        with(Analytics::USER_REGISTRATION_INTRO_VISIT)

      get :start
    end
  end
end
