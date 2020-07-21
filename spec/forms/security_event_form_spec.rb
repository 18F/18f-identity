require 'rails_helper'

RSpec.describe SecurityEventForm do
  include Rails.application.routes.url_helpers

  subject(:form) { SecurityEventForm.new(body: jwt) }

  let(:user) { create(:user) }
  let(:service_provider) { create(:service_provider) }
  let(:rp_private_key) do
    OpenSSL::PKey::RSA.new(
      File.read(Rails.root.join('keys', 'saml_test_sp.key')),
    )
  end
  let(:identity) { IdentityLinker.new(user, service_provider.issuer).link_identity }

  let(:jwt_payload) do
    {
      iss: identity.service_provider,
      jti: SecureRandom.urlsafe_base64,
      iat: Time.zone.now.to_i,
      aud: api_security_events_url,
      events: {
        SecurityEvent::CREDENTIAL_CHANGE_REQUIRED => {
          subject: {
            subject_type: 'iss-sub',
            iss: root_url,
            sub: subject_sub,
          }
        }
      }
    }
  end

  let(:subject_sub) { identity.uuid }
  let(:jwt) { JWT.encode(jwt_payload, rp_private_key, 'RS256') }

  describe '#submit' do
  end

  describe '#valid?' do
    subject(:valid?) { form.valid? }

    context 'with a valid form' do
      it { expect(valid?).to eq(true) }
    end

    context 'JWT' do
      context 'with a body that is not a JWT' do
        let(:jwt) { 'bbb.bbb.bbb' }
        it 'is invalid' do
          expect(valid?).to eq(false)
          expect(form.err).to eq('jwtParse')
        end
      end

      context 'when signed with a different key' do
        let(:rp_private_key) do
          OpenSSL::PKey::RSA.new(
            File.read(Rails.root.join('keys', 'oidc.key')),
          )
        end

        it 'is invalid' do
          expect(valid?).to eq(false)
          expect(form.err).to eq('jws')
        end
      end
    end

    context 'aud' do
      context 'with a wrong audience endpoint URL' do
        before { jwt_payload[:aud] = 'https://bad.example' }
        it 'is invalid' do
          expect(valid?).to eq(false)
        end
      end
    end

    context 'iss' do
      context 'with an unknown issuer' do
        before { jwt_payload[:iss] = 'not.valid.issuer' }
        it 'is invalid' do
          expect(valid?).to eq(false)
        end
      end
    end

    context 'event type' do
      context 'with no events' do
        before { jwt_payload.delete(:events) }

        it 'is invalid' do
          expect(valid?).to eq(false)
          expect(form.err).to eq('setData')
        end
      end

      context 'with a bad event type' do
        before do
          event = jwt_payload[:events].delete(SecurityEvent::CREDENTIAL_CHANGE_REQUIRED)
          jwt_payload[:events]['wrong-event-type'] = event
        end

        it 'is invalid' do
          expect(valid?).to eq(false)
          expect(form.err).to eq('setType')
        end
      end

      context 'with an additional event type' do
        before { jwt_payload[:events] }

        it 'is invalid' do
          expect(valid?).to eq(false)
          expect(form.err).to eq('setType')
        end
      end
    end

    context 'subject_type' do
      context 'with a bad subject type' do
        before do
          event_name, event = jwt_payload[:events].first
          event[:subject][:subject_type] = 'email'
        end

        it 'is invalid' do
          expect(valid?).to eq(false)
          expect(form.err).to eq('setData')
        end
      end
    end

    context 'sub' do
      context 'with a bad uuid' do
        let(:subject_sub) { 'aaa' }
        it 'is invalid' do
          expect(valid?).to eq(false)
          expect(form.err).to eq('setData')
        end
      end

      context 'with a uuid for a different identity' do
        let(:subject_sub) { create(:identity).uuid }
        it 'is invalid' do
          expect(valid?).to eq(false)
          expect(form.err).to eq('setData')
        end
      end
    end
  end
end