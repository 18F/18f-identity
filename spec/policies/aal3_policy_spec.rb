require 'rails_helper'

describe AAL3Policy do
  let(:service_provider) { create(:service_provider, aal: 1) }
  let(:sp_session) { { issuer: service_provider.issuer, aal_level_requested: 1 } }
  let(:session) { { auth_method: 'phone', sp: sp_session } }
  let(:user) { create(:user) }

  describe '#aal3_required?' do
    it 'is false if the SP did not request and does not require AAL3' do
      aal3_policy = AAL3Policy.new(session: session, user: user)

      expect(aal3_policy.aal3_required?).to eq(false)
    end

    it 'is true if the SP requested AAL3' do
      sp_session[:aal_level_requested] = 3
      aal3_policy = AAL3Policy.new(session: session, user: user)

      expect(aal3_policy.aal3_required?).to eq(true)
    end

    it 'is true if the SP is configured for AAL3 only' do
      service_provider.update!(aal: 3)
      aal3_policy = AAL3Policy.new(session: session, user: user)

      expect(aal3_policy.aal3_required?).to eq(true)
    end

    it 'is false if there is no SP' do
      session[:sp] = nil
      aal3_policy = AAL3Policy.new(session: session, user: user)

      expect(aal3_policy.aal3_required?).to eq(false)
    end
  end

  describe '#aal_used?' do
    it 'returns true if the user used PIV/CAC for MFA' do
      session[:auth_method] = 'piv_cac'
      aal3_policy = AAL3Policy.new(session: session, user: user)

      expect(aal3_policy.aal3_used?).to eq(true)
    end

    it 'returns true if the user used webauthn for MFA' do
      session[:auth_method] = 'webauthn'
      aal3_policy = AAL3Policy.new(session: session, user: user)

      expect(aal3_policy.aal3_used?).to eq(true)
    end

    it 'returns false if the user has not used an AAL3 method for MFA' do
      session[:auth_method] = 'phone'
      aal3_policy = AAL3Policy.new(session: session, user: user)

      expect(aal3_policy.aal3_used?).to eq(false)
    end
  end

  describe '#aal3_required_but_not_used?' do
    it 'returns false if AAL3 is not required' do
      aal3_policy = AAL3Policy.new(session: session, user: user)

      expect(aal3_policy.aal3_required_but_not_used?).to eq(false)
    end

    it 'returns true if AAL3 is required and was not used to sign in' do
      sp_session[:aal_level_requested] = 3
      aal3_policy = AAL3Policy.new(session: session, user: user)

      expect(aal3_policy.aal3_required_but_not_used?).to eq(true)
    end

    it 'returns false if AAL3 is required and was used to sign in' do
      sp_session[:aal_level_requested] = 3
      session[:auth_method] = 'webauthn'
      aal3_policy = AAL3Policy.new(session: session, user: user)

      expect(aal3_policy.aal3_required_but_not_used?).to eq(false)
    end
  end

  describe '#aal3_configured_but_not_used?' do
    it 'returns false if AAL3 is configured and not required and not used' do
      configure_aal3_for_user(user)
      aal3_policy = AAL3Policy.new(session: session, user: user)

      expect(aal3_policy.aal3_configured_but_not_used?).to eq(false)
    end

    it 'returns false if AAL3 is not configured' do
      sp_session[:aal_level_requested] = 3
      aal3_policy = AAL3Policy.new(session: session, user: user)

      expect(aal3_policy.aal3_configured_but_not_used?).to eq(false)
    end

    it 'returns true if AAL3 is configured and was not used to sign in' do
      sp_session[:aal_level_requested] = 3
      configure_aal3_for_user(user)
      aal3_policy = AAL3Policy.new(session: session, user: user)

      expect(aal3_policy.aal3_configured_but_not_used?).to eq(true)
    end

    it 'returns false if AAL3 is configured and was used to sign in' do
      sp_session[:aal_level_requested] = 3
      configure_aal3_for_user(user)
      session[:auth_method] = 'webauthn'
      aal3_policy = AAL3Policy.new(session: session, user: user)

      expect(aal3_policy.aal3_configured_but_not_used?).to eq(false)
    end
  end

  def configure_aal3_for_user(user)
    user.webauthn_configurations << create(:webauthn_configuration)
    user.save!
  end
end
