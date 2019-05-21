class RegisterUserEmailForm
  include ActiveModel::Model
  include FormEmailValidator

  def self.model_name
    ActiveModel::Name.new(self, nil, 'User')
  end

  def initialize(recaptcha_results = [true, {}])
    @allow, @recaptcha_h = recaptcha_results
  end

  def user
    @user ||= User.new
  end

  def email
    @email || user.email
  end

  def resend
    'true'
  end

  def submit(params, instructions = nil)
    user.email = params[:email]
    request_id = params[:request_id]

    if valid_form?
      process_successful_submission(request_id, instructions)
    else
      @success = @allow && process_errors(request_id)
    end

    FormResponse.new(success: success, errors: errors.messages, extra: extra_analytics_attributes)
  end

  private

  attr_writer :email
  attr_reader :success

  def valid_form?
    @allow && valid? && !email_taken?
  end

  def process_successful_submission(request_id, instructions)
    @success = true
    user.save!
    SendSignUpEmailConfirmation.new(user).call(request_id: request_id, instructions: instructions)
  end

  def extra_analytics_attributes
    {
      email_already_exists: email_taken?,
      user_id: existing_user.uuid,
      domain_name: email&.split('@')&.last,
    }.merge(@recaptcha_h)
  end

  def process_errors(request_id)
    # To prevent discovery of existing emails, we check to see if the email is
    # already taken and if so, we act as if the user registration was successful.
    if email_taken? && user_unconfirmed?
      SendSignUpEmailConfirmation.new(existing_user).call(request_id: request_id)
      true
    elsif email_taken?
      UserMailer.signup_with_your_email(email).deliver_later
      true
    else
      false
    end
  end

  def user_unconfirmed?
    existing_user.email_addresses.none?(&:confirmed?)
  end

  def existing_user
    @_user ||= User.find_with_email(email) || AnonymousUser.new
  end
end
