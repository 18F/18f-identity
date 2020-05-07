require 'rails_helper'

RSpec.describe VerifySPAttributesConcern do
  controller ApplicationController do
    # ApplicationController already includes VerifySPAttributesConcern
  end

  describe '#consent_has_expired?' do
    let(:sp_session_identity) { build(:identity, user: user) }
    let(:user) { build(:user) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:sp_session_identity).and_return(sp_session_identity)
    end

    subject(:consent_has_expired?) { controller.consent_has_expired? }

    context 'when there is no sp_session_identity' do
      let(:sp_session_identity) { nil }
      it 'is false' do
        expect(consent_has_expired?).to eq(false)
      end
    end

    context 'when there is no last_consented_at' do
      it 'is true' do
        expect(consent_has_expired?).to eq(true)
      end
    end

    context 'when last_consented_at within one year' do
      let(:sp_session_identity) { build(:identity, last_consented_at: 5.days.ago) }

      it 'is false' do
        expect(consent_has_expired?).to eq(false)
      end
    end

    context 'when the last_consented_at is older than a year ago' do
      let(:sp_session_identity) { build(:identity, last_consented_at: 2.years.ago) }

      it 'is true' do
        expect(consent_has_expired?).to eq(true)
      end
    end

    context 'when last_consented_at is nil but created_at is within a year' do
      let(:sp_session_identity) do
        build(:identity, last_consented_at: nil, created_at: 4.days.ago)
      end

      it 'is false' do
        expect(consent_has_expired?).to eq(false)
      end
    end

    context 'when last_consented_at is nil and created_at is older than a year' do
      let(:sp_session_identity) do
        build(:identity, last_consented_at: nil, created_at: 4.years.ago)
      end

      it 'is true' do
        expect(consent_has_expired?).to eq(true)
      end
    end

    context 'when the identity has been soft-deleted (consent has been revoked)' do
      let(:sp_session_identity) do
        build(:identity,
              deleted_at: 1.day.ago,
              last_consented_at: 2.years.ago)
      end

      it 'is false' do
        expect(consent_has_expired?).to eq(false)
      end
    end

    context 'when there is an active profile' do
      let(:sp_session_identity) do
        create(:identity, last_consented_at: 15.days.ago, user: user)
      end

      before do
        create(:profile, :active, verified_at: verified_at, user: user)
      end

      context 'when the active profile was verified after last_consented_at' do
        let(:verified_at) { 5.days.ago }
        it 'is true because the new verified data needs to be consented to sharing' do
          expect(consent_has_expired?).to eq(true)
        end
      end

      context 'when the active profile was verified before last_consented_at' do
        let(:verified_at) { 20.days.ago }
        it 'is false' do
          expect(consent_has_expired?).to eq(false)
        end
      end
    end
  end

  describe '#consent_was_revoked?' do
    let(:sp_session_identity) { build(:identity) }

    before do
      allow(controller).to receive(:sp_session_identity).and_return(sp_session_identity)
    end

    subject(:consent_was_revoked?) { controller.consent_was_revoked? }

    context 'when there is no sp_session_identity' do
      let(:sp_session_identity) { nil }
      it 'is false' do
        expect(consent_was_revoked?).to eq(false)
      end
    end

    context 'when the sp_session_identity exists and has not been deleted' do
      it 'is false' do
        expect(consent_was_revoked?).to eq(false)
      end
    end

    context 'when the sp_session_identity exists and has been deleted' do
      let(:sp_session_identity) { build(:identity, deleted_at: 2.days.ago) }

      it 'is false' do
        expect(consent_was_revoked?).to eq(true)
      end
    end
  end
end
