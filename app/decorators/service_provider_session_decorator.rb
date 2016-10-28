class ServiceProviderSessionDecorator
  def initialize(sp_name:)
    @sp_name = sp_name
  end

  def nav_partial
    'shared/nav_branded'
  end

  def back_to_service_provider_link
    I18n.t('links.back_to_sp', sp: sp_name)
  end

  def new_session_heading
    I18n.t('headings.log_in_branded', sp: sp_name)
  end

  def registration_heading
    I18n.t('headings.create_account_with_sp', sp: sp_name)
  end

  def registration_bullet_1
    I18n.t('devise.registrations.start.bullet_1_with_sp', sp: sp_name)
  end

  private

  attr_reader :sp_name
end
