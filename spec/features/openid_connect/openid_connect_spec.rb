require 'rails_helper'

feature 'OpenID Connect' do
  context 'with client_secret_jwt' do
    it 'succeeds' do
      client_id = 'urn:gov:gsa:openidconnect:sp:server'
      state = SecureRandom.hex
      nonce = SecureRandom.hex

      visit openid_connect_authorize_path(
        client_id: client_id,
        response_type: 'code',
        acr_values: Saml::Idp::Constants::LOA3_AUTHN_CONTEXT_CLASSREF,
        scope: 'openid email profile:name social_security_number',
        redirect_uri: 'http://localhost:7654/auth/result',
        state: state,
        prompt: 'select_account',
        nonce: nonce
      )

      user = create(:profile, :active, :verified,
                    pii: { first_name: 'John', ssn: '111223333' }).user

      sign_in_live_with_2fa(user)
      expect(page.response_headers['Content-Security-Policy']).
        to(include('form-action \'self\' http://localhost:7654'))
      click_button t('openid_connect.authorization.index.allow')

      redirect_uri = URI(current_url)
      redirect_params = Rack::Utils.parse_query(redirect_uri.query).with_indifferent_access

      expect(redirect_uri.to_s).to start_with('http://localhost:7654/auth/result')
      expect(redirect_params[:state]).to eq(state)

      code = redirect_params[:code]
      expect(code).to be_present

      jwt_payload = {
        iss: client_id,
        sub: client_id,
        aud: api_openid_connect_token_url,
        jti: SecureRandom.hex,
        exp: 5.minutes.from_now.to_i,
      }

      client_assertion = JWT.encode(jwt_payload, client_private_key, 'RS256')
      client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'

      page.driver.post api_openid_connect_token_path,
                       grant_type: 'authorization_code',
                       code: code,
                       client_assertion_type: client_assertion_type,
                       client_assertion: client_assertion

      expect(page.status_code).to eq(200)
      token_response = JSON.parse(page.body).with_indifferent_access

      id_token = token_response[:id_token]
      expect(id_token).to be_present

      decoded_id_token, _headers = JWT.decode(
        id_token, sp_public_key, true, algorithm: 'RS256'
      ).map(&:with_indifferent_access)

      sub = decoded_id_token[:sub]
      expect(sub).to be_present
      expect(decoded_id_token[:nonce]).to eq(nonce)
      expect(decoded_id_token[:aud]).to eq(client_id)
      expect(decoded_id_token[:acr]).to eq(Saml::Idp::Constants::LOA3_AUTHN_CONTEXT_CLASSREF)
      expect(decoded_id_token[:iss]).to eq(root_url)
      expect(decoded_id_token[:email]).to eq(user.email)
      expect(decoded_id_token[:given_name]).to eq('John')
      expect(decoded_id_token[:social_security_number]).to eq('111223333')

      access_token = token_response[:access_token]
      expect(access_token).to be_present

      page.driver.get api_openid_connect_userinfo_path,
                      {},
                      'HTTP_AUTHORIZATION' => "Bearer #{access_token}"

      userinfo_response = JSON.parse(page.body).with_indifferent_access
      expect(userinfo_response[:sub]).to eq(sub)
      expect(userinfo_response[:email]).to eq(user.email)
      expect(userinfo_response[:given_name]).to eq('John')
      expect(userinfo_response[:social_security_number]).to eq('111223333')
    end

    it 'auto-allows with a second authorization and sets the correct CSP headers' do
      client_id = 'urn:gov:gsa:openidconnect:sp:server'
      user = user_with_2fa

      IdentityLinker.new(user, client_id).link_identity

      visit openid_connect_authorize_path(
        client_id: client_id,
        response_type: 'code',
        acr_values: Saml::Idp::Constants::LOA1_AUTHN_CONTEXT_CLASSREF,
        scope: 'openid email',
        redirect_uri: 'http://localhost:7654/auth/result',
        state: SecureRandom.hex,
        nonce: SecureRandom.hex,
        prompt: 'select_account'
      )

      sp_request_id = ServiceProviderRequest.last.uuid
      allow(FeatureManagement).to receive(:prefill_otp_codes?).and_return(true)
      sign_in_user(user)

      expect(page.response_headers['Content-Security-Policy']).
        to(include('form-action \'self\' http://localhost:7654'))

      click_submit_default

      expect(current_url).to start_with('http://localhost:7654/auth/result')
      expect(ServiceProviderRequest.from_uuid(sp_request_id)).
        to be_a NullServiceProviderRequest
      expect(page.get_rack_session.keys).to_not include('sp')
    end
  end

  context 'with PCKE' do
    it 'succeeds with client authentication via PKCE' do
      client_id = 'urn:gov:gsa:openidconnect:test'
      state = SecureRandom.hex
      nonce = SecureRandom.hex
      code_verifier = SecureRandom.hex
      code_challenge = Digest::SHA256.base64digest(code_verifier)

      visit openid_connect_authorize_path(
        client_id: client_id,
        response_type: 'code',
        acr_values: Saml::Idp::Constants::LOA1_AUTHN_CONTEXT_CLASSREF,
        scope: 'openid email',
        redirect_uri: 'gov.gsa.openidconnect.test://result',
        state: state,
        prompt: 'select_account',
        nonce: nonce,
        code_challenge: code_challenge,
        code_challenge_method: 'S256'
      )

      _user = sign_in_live_with_2fa
      expect(page.html).to_not include(code_challenge)
      click_button t('openid_connect.authorization.index.allow')

      redirect_uri = URI(current_url)
      redirect_params = Rack::Utils.parse_query(redirect_uri.query).with_indifferent_access

      expect(redirect_uri.to_s).to start_with('gov.gsa.openidconnect.test://result')
      expect(redirect_params[:state]).to eq(state)

      code = redirect_params[:code]
      expect(code).to be_present

      page.driver.post api_openid_connect_token_path,
                       grant_type: 'authorization_code',
                       code: code,
                       code_verifier: code_verifier

      expect(page.status_code).to eq(200)
      token_response = JSON.parse(page.body).with_indifferent_access

      id_token = token_response[:id_token]
      expect(id_token).to be_present
    end

    it 'continues to the branded authorization page on first-time signup', email: true do
      client_id = 'urn:gov:gsa:openidconnect:test'
      email = 'test@test.com'

      perform_in_browser(:one) do
        visit openid_connect_authorize_path(
          client_id: client_id,
          response_type: 'code',
          acr_values: Saml::Idp::Constants::LOA1_AUTHN_CONTEXT_CLASSREF,
          scope: 'openid email',
          redirect_uri: 'gov.gsa.openidconnect.test://result',
          state: SecureRandom.hex,
          nonce: SecureRandom.hex,
          prompt: 'select_account',
          code_challenge: Digest::SHA256.base64digest(SecureRandom.hex),
          code_challenge_method: 'S256'
        )

        expect(page).to have_content(t('headings.create_account_with_sp', sp: 'Example iOS App'))

        sign_up_user_from_sp_without_confirming_email(email)
      end

      sp_request_id = ServiceProviderRequest.last.uuid

      perform_in_browser(:two) do
        confirm_email_in_a_different_browser(email)

        click_button t('forms.buttons.continue_to', sp: 'Example iOS App')
        click_button t('openid_connect.authorization.index.allow')
        redirect_uri = URI(current_url)
        expect(redirect_uri.to_s).to start_with('gov.gsa.openidconnect.test://result')
        expect(ServiceProviderRequest.from_uuid(sp_request_id)).
          to be_a NullServiceProviderRequest
        expect(page.get_rack_session.keys).to_not include('sp')
      end
    end
  end

  def sp_public_key
    page.driver.get api_openid_connect_certs_path

    expect(page.status_code).to eq(200)
    certs_response = JSON.parse(page.body).with_indifferent_access

    JSON::JWK.new(certs_response[:keys].first).to_key
  end

  def client_private_key
    @client_private_key ||= begin
      OpenSSL::PKey::RSA.new(
        File.read(Rails.root.join('keys', 'saml_test_sp.key'))
      )
    end
  end
end
