module Users
  class RegistrationsController < Devise::RegistrationsController
    include PhoneConfirmation

    before_action :confirm_two_factor_authenticated, only: [:destroy_confirm]
    prepend_before_action :disable_account_creation, only: [:new, :create]

    def start
      analytics.track_event(Analytics::USER_REGISTRATION_INTRO_VISIT)
    end

    def new
      ab_finished(:demo)
      @register_user_email_form = RegisterUserEmailForm.new
      analytics.track_event(Analytics::USER_REGISTRATION_ENTER_EMAIL_VISIT)
    end

    # POST /resource
    def create
      @register_user_email_form = RegisterUserEmailForm.new

      result = @register_user_email_form.submit(permitted_params)

      analytics.track_event(Analytics::USER_REGISTRATION_EMAIL, result)

      if result[:success]
        process_successful_creation
      else
        render :new
      end
    end

    def destroy_confirm
    end

    protected

    def permitted_params
      params.require(:user).permit(:email)
    end

    def process_successful_creation
      user = @register_user_email_form.user
      create_user_event(:account_created, user) unless @register_user_email_form.email_taken?

      @resend_confirmation = params[:user][:resend]

      render :verify_email, locals: { email: user.email }
    end

    def disable_account_creation
      redirect_to root_path if AppSetting.registrations_disabled?
    end
  end
end
