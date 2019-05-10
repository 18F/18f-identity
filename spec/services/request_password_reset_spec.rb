require 'rails_helper'

describe RequestPasswordReset do
  describe '#perform' do
    context 'when the user is not found' do
      it 'sends the account registration email' do
        email = 'nonexistent@example.com'
        expect_any_instance_of(User).to receive(:send_custom_confirmation_instructions).
          with(nil, I18n.t('mailer.confirmation_instructions.first_sentence.forgot_password'))
        RequestPasswordReset.new(email).perform
        expect(User.find_with_email(email)).to be_present
      end
    end

    context 'when the user is found, not privileged, and confirmed' do
      it 'sends password reset instructions' do
        user = build_stubbed(:user)

        allow(User).to receive(:find_with_email).with(user.email).and_return(user)

        expect(user).to receive(:send_reset_password_instructions)

        RequestPasswordReset.new(user.email).perform
      end
    end

    context 'when the user is found, not privileged, and not yet confirmed' do
      it 'sends password reset instructions' do
        user = build_stubbed(:user, :unconfirmed)

        allow(User).to receive(:find_with_email).with(user.email).and_return(user)

        expect(user).to receive(:send_reset_password_instructions)

        RequestPasswordReset.new(user.email).perform
      end
    end
  end
end
