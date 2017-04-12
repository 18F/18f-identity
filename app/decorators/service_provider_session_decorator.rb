class ServiceProviderSessionDecorator
  DEFAULT_LOGO = 'generic.svg'.freeze

  def initialize(sp:, view_context:)
    @sp = sp
    @view_context = view_context
  end

  def sp_logo
    sp.logo || DEFAULT_LOGO
  end

  def return_to_service_provider_partial
    'devise/sessions/return_to_service_provider'
  end

  def nav_partial
    'shared/nav_branded'
  end

  def new_session_heading
    I18n.t('headings.sign_in_with_sp', sp: sp_name)
  end

  def registration_heading
    'sign_up/registrations/sp_registration_heading'
  end

  def verification_method_choice
    I18n.t('idv.messages.select_verification_with_sp', sp_name: sp_name)
  end

  def idv_hardfail4_partial
    'verify/hardfail4'
  end

  def sp_name
    sp.friendly_name || sp.agency
  end

  def sp_return_url
    sp.return_to_sp_url
  end

  private

  attr_reader :sp, :view_context
end
