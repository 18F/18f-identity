require 'rails_helper'

describe IdentityDecorator do
  let(:user) { create(:user) }
  let(:identity) { create(:identity, :active, user: user) }

  subject { IdentityDecorator.new(identity) }

  describe '#pretty_event_type' do
    it 'returns the localized text corresponding to the identity event' do
      expect(subject.pretty_event_type).to eq(
        t('event_types.authenticated_at', service_provider: identity.display_name)
      )
    end
  end

  describe '#happened_at' do
    it 'returns last_authenticated_at' do
      expect(subject.happened_at).to eq identity.last_authenticated_at
    end
  end
end
