require 'rails_helper'

describe 'devise/registrations/new.html.slim' do
  before do
    @register_user_email_form = RegisterUserEmailForm.new
    allow(view).to receive(:controller_name).and_return('registrations')
  end

  it 'has a localized title' do
    expect(view).to receive(:title).with(t('titles.registrations.new'))

    render
  end

  it 'includes a link to terms of service' do
    render

    expect(rendered).
      to have_link(t('notices.terms_of_service.link'), href: privacy_path)
  end

  it 'sets form autocomplete to off' do
    render

    expect(rendered).to have_xpath("//form[@autocomplete='off']")
  end
end
