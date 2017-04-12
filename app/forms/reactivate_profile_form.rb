class ReactivateProfileForm
  include ActiveModel::Model

  validates :personal_key, :password, presence: true
  validate :validate_password_reset_profile
  validate :validate_password
  validate :validate_personal_key

  attr_accessor :personal_key, :password
  attr_reader :user

  def initialize(user, attrs = {})
    attrs[:personal_key] ||= []
    @user = user
    super attrs

    @personal_key = personal_key.join(' ')
  end

  def submit(flash)
    if valid?
      flash[:personal_key] = reencrypt_pii
      true
    else
      clear_fields
      false
    end
  end

  protected

  def password_reset_profile
    @_password_reset_profile ||= user.decorate.password_reset_profile
  end

  def user_access_key
    @_uak ||= user.unlock_user_access_key(password)
  end

  def decrypted_pii
    @_pii ||= password_reset_profile.recover_pii(personal_key)
  end

  def reencrypt_pii
    personal_key = password_reset_profile.encrypt_pii(user_access_key, decrypted_pii)
    password_reset_profile.deactivation_reason = nil
    password_reset_profile.save!
    personal_key
  end

  def validate_password_reset_profile
    errors.add :base, :no_password_reset_profile unless password_reset_profile
  end

  def validate_password
    return if password.blank? || valid_password?
    errors.add :password, :password_incorrect
  end

  def validate_personal_key
    return if personal_key.blank? || (valid_personal_key? && personal_key_decrypts?)
    errors.add :personal_key, :personal_key_incorrect
  end

  # Reset sensitive fields so they don't get sent back to the browser
  def clear_fields
    self.password = nil
  end

  def valid_password?
    user.valid_password?(password)
  end

  def personal_key_decrypts?
    decrypted_pii.present?
  rescue Pii::EncryptionError => _err
    false
  end

  def valid_personal_key?
    PersonalKeyGenerator.new(user).verify(personal_key)
  end
end
