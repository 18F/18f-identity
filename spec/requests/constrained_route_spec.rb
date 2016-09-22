require 'rails_helper'

describe 'routes that require admin + 2FA' do
  def sign_in_user(user)
    post_via_redirect(
      new_user_session_path,
      'user[email]' => user.email,
      'user[password]' => user.password
    )
    get_via_redirect otp_send_path(otp_delivery_selection_form: { otp_method: 'sms' })
    post_via_redirect(
      login_two_factor_path(delivery_method: 'sms'),
      'code' => user.reload.direct_otp
    )
  end

  shared_examples 'constrained route' do |endpoint|
    context 'user is signed in via 2FA but is not an admin' do
      it 'does not allow access' do
        user = create(:user, :signed_up)
        sign_in_user(user)

        expect { get endpoint }.to raise_error ActionController::RoutingError
      end
    end

    context 'user is an admin but is not signed in via 2FA' do
      it 'does not allow access' do
        user = create(:user, :signed_up, :admin)

        post_via_redirect(
          new_user_session_path,
          'user[email]' => user.email,
          'user[password]' => user.password
        )

        expect { get endpoint }.to raise_error ActionController::RoutingError
      end
    end

    context 'user is an admin and is signed in via 2FA' do
      it 'allows access' do
        user = create(:user, :signed_up, :admin)
        sign_in_user(user)

        expect { get endpoint }.to_not raise_error
      end
    end
  end

  it_behaves_like 'constrained route', '/sidekiq'
  it_behaves_like 'constrained route', '/split'
end
