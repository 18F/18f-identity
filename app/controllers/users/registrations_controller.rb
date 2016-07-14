module Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :confirm_two_factor_authenticated, only: [:edit, :update, :destroy_confirm]
    prepend_before_action :authenticate_scope!, only: [
      :edit, :edit_field, :update, :update_field, :destroy, :destroy_confirm
    ]
    prepend_before_action :disable_account_creation, only: [:new, :create]

    def start
    end

    def new
      ab_finished(:demo)
      @register_user_email_form = RegisterUserEmailForm.new
    end

    # POST /resource
    def create
      @register_user_email_form = RegisterUserEmailForm.new

      if @register_user_email_form.submit(params[:user])
        process_successful_creation

        track_registration(@register_user_email_form)
      else
        analytics.track_anonymous_event(
          'User Registration: invalid email', @register_user_email_form.email
        )
        render :new
      end
    end

    def edit
      @update_form = UpdateUserProfileForm.new(resource)
    end

    def update
      @update_form = UpdateUserProfileForm.new(resource)

      if @update_form.submit(user_params)
        process_successful_update(resource)
      else
        clean_up_passwords resource
        render :edit
      end
    end

    def edit_field
      field = params[:field]

      @update_form = update_field_form(field).new(resource)
      render :"edit_#{field}"
    end

    def update_field
      field = params[:field]

      @update_form = update_field_form(field).new(resource)

      if @update_form.submit(user_params)
        process_successful_update(resource)
      else
        clean_up_passwords resource
        render :"edit_#{field}"
      end
    end

    def destroy_confirm
    end

    protected

    def update_field_form(field)
      "UpdateUser#{field.capitalize}Form".constantize
    end

    def process_successful_update(resource)
      process_updates(resource)
      bypass_sign_in resource
    end

    def process_updates(resource)
      updater = UserFlashUpdater.new(resource, flash)

      updater.set_flash_message

      if updater.needs_to_confirm_mobile_change?
        process_redirection(resource)
      elsif is_flashing_format?
        profile_form = @update_form.is_a?(UpdateUserProfileForm)
        redirect_to profile_form ? edit_user_registration_url : profile_index_url
        EmailNotifier.new(resource).send_password_changed_email
      end
    end

    def process_redirection(resource)
      resource.send_new_otp unless @update_form.mobile_taken?

      redirect_to user_two_factor_authentication_path
    end

    def process_successful_creation
      render :verify_email, locals: { email: @register_user_email_form.user.email }
    end

    def disable_account_creation
      redirect_to root_path if AppSetting.registrations_disabled?
    end

    def user_params
      params.require(@update_form.class.name.underscore.to_sym).
        permit(:mobile, :email, :password, :current_password)
    end

    def track_registration(form)
      return analytics.track_event('Account Created', form.user) unless form.email_taken?

      existing_user = User.find_by_email(form.email)
      analytics.track_event('Registration Attempt with existing email', existing_user)
    end
  end
end
