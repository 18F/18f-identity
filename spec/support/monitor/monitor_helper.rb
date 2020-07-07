require 'support/monitor/monitor_url_helper'

# For the "monitor" aka smoke tests
# This class and its method allow us to run the tests against local code so we
# can test in CI as well as against deployed environments
class MonitorHelper
  include MonitorUrlHelper

  attr_reader :context

  def initialize(context)
    @context = context
  end

  def config
    @config ||= MonitorConfig.new
  end

  def email
    @email ||= MonitorEmailHelper.new(email: config.email_address, password: config.password, local: local?)
  end

  def setup
    if local?
      context.create(:user, email: config.sms_sign_in_email, password: config.password)
    else
      config.check_env_variables!
      reset_sessions
      email.inbox_clear
    end
  end

  def local?
    defined?(Rails) && Rails.env.test?
  end

  # Capybara.reset_session! deletes the cookies for the current site. As such
  # we need to visit each site individually and reset there.
  def reset_sessions
    context.visit config.idp_signin_url
    Capybara.reset_session!
    context.visit config.oidc_sp_url if config.oidc_sp_url
    Capybara.reset_session!
    context.visit config.saml_sp_url if config.saml_sp_url
    Capybara.reset_session!
  end

  def check_for_password_reset_link
    email.scan_emails_and_extract(
      subject: 'Reset your password',
      regex: /(?<link>https?:.+reset_password_token=[\w\-]+)/,
    )
  end

  def check_for_confirmation_link
    email.scan_emails_and_extract(
      subject: [
        'Confirm your email',
        'Email not found',
      ],
      regex: /(?<link>https?:.+confirmation_token=[\w\-]+)/,
    )
  end

  def check_for_otp
    otp_regex = /Enter (?<code>\d{6}) in login\.gov/

    if local?
      match_data = Telephony::Test::Message.messages.last.body.match(otp_regex)
      return match_data[:code] if match_data
    else
      email.scan_emails_and_extract(regex: otp_regex)
    end
  end
end
