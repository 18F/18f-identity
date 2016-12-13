require 'rails_helper'

describe TwoFactorAuthentication::RecoveryCodeController do
  describe '#show' do
    it 'generates a new recovery code' do
      stub_sign_in
      generator = instance_double(RecoveryCodeGenerator)
      allow(RecoveryCodeGenerator).to receive(:new).
        with(subject.current_user).and_return(generator)

      expect(generator).to receive(:create)

      get :show
    end

    context 'when there is no session (signed out or locked out), and the user reloads the page' do
      it 'redirects to the home page' do
        expect(controller.user_session).to be_nil

        get :show

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
