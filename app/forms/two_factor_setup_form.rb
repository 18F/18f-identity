class TwoFactorSetupForm
  include ActiveModel::Model
  include FormPhoneValidator

  attr_accessor :phone

  def initialize(user)
    @user = user
  end

  def submit(params)
    self.phone = params[:phone].phony_formatted(
      format: :international, normalize: :US, spaces: ' '
    )
    self.otp_method = params[:otp_method]

    @success = valid?

    update_otp_delivery_preference_for_user if success && otp_delivery_preference_changed?

    FormResponse.new(success: success, errors: errors.messages, extra: extra_analytics_attributes)
  end

  private

  attr_reader :success, :user
  attr_accessor :otp_method

  def otp_delivery_preference_changed?
    otp_method != user.otp_delivery_preference
  end

  def update_otp_delivery_preference_for_user
    user_attributes = { otp_delivery_preference: otp_method }
    UpdateUser.new(user: user, attributes: user_attributes).call
  end

  def extra_analytics_attributes
    {
      otp_method: otp_method,
    }
  end
end
