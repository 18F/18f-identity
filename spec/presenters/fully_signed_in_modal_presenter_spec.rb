require 'rails_helper'

describe FullySignedInModalPresenter do
  include ActionView::Helpers::TagHelper

  let(:time_left_in_session) { 10 }
  subject(:presenter) { FullySignedInModalPresenter.new(time_left_in_session) }

  describe '#message' do
    it 'returns the fully signed in message' do
      message = t(
        'notices.timeout_warning.signed_in.message_html',
        time_left_in_session: content_tag(:span, time_left_in_session, id: 'countdown'),
      )

      expect(presenter.message).to eq message
    end
  end

  describe '#continue' do
    it 'uses the fully signed in localization' do
      expect(presenter.continue).to eq t('notices.timeout_warning.signed_in.continue')
    end
  end

  describe '#sign_out' do
    it 'uses the fully signed in localization' do
      expect(presenter.sign_out).to eq t('notices.timeout_warning.signed_in.sign_out')
    end
  end
end
