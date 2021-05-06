require 'rails_helper'

RSpec.describe OpenidConnectCertsPresenter do
  subject(:presenter) { OpenidConnectCertsPresenter.new }

  describe '#certs' do
    it 'renders the server public key as a JWK set' do
      json = presenter.certs

      expect(json[:keys].size).to eq(1)

      key_from_response = JWT::JWK.import(json[:keys].first).public_key
      public_key = AppArtifacts.store.oidc_public_key

      expect(key_from_response.to_pem).to eq(public_key.to_pem)
    end
  end
end
