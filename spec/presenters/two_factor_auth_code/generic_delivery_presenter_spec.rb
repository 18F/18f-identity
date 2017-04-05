require 'rails_helper'

def presenter_with(arguments = {}, view = nil)
  TwoFactorAuthCode::GenericDeliveryPresenter.new(arguments, view)
end

describe TwoFactorAuthCode::GenericDeliveryPresenter do
  it 'is an abstract presenter with methods that should be implemented' do
    presenter = presenter_with

    %w(header help_text fallback_links).each do |m|
      expect { presenter.send(m.to_sym) }.to raise_error(NotImplementedError)
    end
  end

  describe 'view context' do
    it 'makes the view context available' do
      view = ActionController::Base.new.view_context
      presenter = presenter_with({}, view)
      expect(presenter.view).to equal(view)
    end
  end

  describe '#personal_key_link' do
    context 'with unconfirmed user' do
      presenter = presenter_with(personal_key_unavailable: true)

      it 'returns without providing the option to use a personal key' do
        expect(presenter.personal_key_link).to be_nil
      end
    end

    context 'with confirmed user' do
      presenter = presenter_with(personal_key_unavailable: false)

      it 'returns a personal key link' do
        expect(presenter.personal_key_link).not_to be_nil
      end
    end
  end
end
