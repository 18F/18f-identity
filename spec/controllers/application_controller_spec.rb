require 'rails_helper'

describe ApplicationController do
  describe 'handling InvalidAuthenticityToken exceptions' do
    controller do
      def index
        raise ActionController::InvalidAuthenticityToken
      end
    end

    it 'tracks the InvalidAuthenticityToken event and signs user out' do
      sign_in_as_user
      expect(subject.current_user).to be_present

      stub_analytics
      expect(@analytics).to receive(:track_event).with(Analytics::INVALID_AUTHENTICITY_TOKEN)

      get :index

      expect(flash[:error]).to eq t('errors.invalid_authenticity_token')
      expect(response).to redirect_to(root_url)
      expect(subject.current_user).to be_nil
    end
  end

  describe '#append_info_to_payload' do
    let(:payload) { {} }

    it 'adds user_id, user_agent and ip to the lograge output' do
      Timecop.freeze(Time.zone.now) do
        subject.append_info_to_payload(payload)

        expect(payload.keys).to eq [:user_id, :user_agent, :ip, :host]
        expect(payload.values).
          to eq ['anonymous-uuid', request.user_agent, request.remote_ip, request.host]
      end
    end
  end

  describe '#confirm_two_factor_authenticated' do
    controller do
      before_action :confirm_two_factor_authenticated

      def index
        render text: 'Hello'
      end
    end

    context 'not signed in' do
      it 'redirects to sign in page' do
        get :index

        expect(response).to redirect_to root_url
      end
    end

    context 'is not 2FA-enabled' do
      it 'redirects to phone_setup_url with a flash message' do
        user = create(:user)
        sign_in user

        get :index

        expect(response).to redirect_to phone_setup_url
      end
    end

    context 'is 2FA-enabled' do
      it 'prompts user to enter their OTP' do
        sign_in_before_2fa

        get :index

        expect(response).to redirect_to user_two_factor_authentication_url
      end
    end
  end

  describe '#analytics' do
    context 'when a current_user is present' do
      it 'calls the Analytics class by default with current_user and request parameters' do
        user = build_stubbed(:user)
        allow(controller).to receive(:current_user).and_return(user)

        expect(Analytics).to receive(:new).with(user, request)

        controller.analytics
      end
    end

    context 'when a current_user is not present' do
      it 'calls the Analytics class with AnonymousUser.new and request parameters' do
        allow(controller).to receive(:current_user).and_return(nil)

        user = instance_double(AnonymousUser)
        allow(AnonymousUser).to receive(:new).and_return(user)

        expect(Analytics).to receive(:new).with(user, request)

        controller.analytics
      end
    end
  end

  describe '#create_user_event' do
    let(:user) { build_stubbed(:user) }

    context 'when the user is not specified' do
      it 'creates an Event object for the current_user' do
        allow(subject).to receive(:current_user).and_return(user)

        expect(Event).to receive(:create).with(user_id: user.id, event_type: :account_created)

        subject.create_user_event(:account_created)
      end
    end

    context 'when the user is specified' do
      it 'creates an Event object for the specified user' do
        expect(Event).to receive(:create).with(user_id: user.id, event_type: :account_created)

        subject.create_user_event(:account_created, user)
      end
    end
  end
end
