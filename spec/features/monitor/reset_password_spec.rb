RSpec.describe 'password reset' do
  let(:monitor) { MonitorHelper.new(self) }

  before { monitor.setup }

  it 'resets password at LOA1' do
    visit monitor.idp_reset_password_url
    fill_in 'password_reset_email_form_email', with: monitor.sms_sign_in_email
    click_on 'Continue'

    expect(page).to have_content('Check your email')

    reset_link = monitor.check_for_password_reset_link
    expect(reset_link).to be_present
    visit reset_link
    fill_in 'reset_password_form_password', with: monitor.password
    click_on 'Change password'

    expect(page).to have_content('Your password has been changed')
  end
end
