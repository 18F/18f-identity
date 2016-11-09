require 'rails_helper'

describe Identity do
  let(:user) { create(:user, :signed_up) }
  let(:identity) { create(:identity, user: user, service_provider: 'externalapp') }
  subject { identity }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_many(:sessions) }
  it { is_expected.to validate_presence_of(:service_provider) }

  describe '#deactivate' do
    let(:session_id) { SecureRandom.uuid }
    let(:active_identity) { create(:identity, :active, session: session_id) }

    it 'destroys corresponding Session' do
      expect(active_identity.sessions.any?).to eq true

      active_identity.deactivate(session_id)
      active_identity.reload

      expect(active_identity.sessions.any?).to eq false
    end
  end

  describe 'uuid validations' do
    it 'uses a DB constraint to enforce presence' do
      identity = create(:identity)
      identity.uuid = nil

      expect { identity.save }.
        to raise_error(ActiveRecord::StatementInvalid,
                       /null value in column "uuid" violates not-null constraint/)
    end

    it 'uses a DB index to enforce uniqueness' do
      identity1 = create(:identity)
      identity1.save
      identity2 = create(:identity)
      identity2.uuid = identity1.uuid

      expect { identity2.save }.
        to raise_error(ActiveRecord::StatementInvalid,
                       /duplicate key value violates unique constraint/)
    end
  end

  describe '#generate_uuid' do
    it 'calls generate_uuid before creation' do
      identity = build(:identity, uuid: 'foo')

      expect(identity).to receive(:generate_uuid)

      identity.save
    end

    context 'when already has a uuid' do
      it 'returns the current uuid' do
        identity = create(:identity)
        old_uuid = identity.uuid

        expect(identity.generate_uuid).to eq old_uuid
      end
    end

    context 'when does not already have a uuid' do
      it 'generates it via SecureRandom.uuid' do
        identity = build(:identity)

        expect(identity.generate_uuid).
          to match(/[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/)
      end
    end
  end

  describe '#decorate' do
    it 'returns a IdentityDecorator' do
      identity = build(:identity)

      expect(identity.decorate).to be_a(IdentityDecorator)
    end
  end
end
