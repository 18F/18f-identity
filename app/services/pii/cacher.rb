module Pii
  class Cacher
    def initialize(user, user_session)
      @user = user
      @user_session = user_session
    end

    def save(password, profile = user.active_profile)
      return unless profile
      decrypted_pii = profile.decrypt_pii(password)
      pii_json = decrypted_pii.to_json
      encrypted_pii = encryptor.encrypt(pii_json)
      user_session[:encrypted_pii] = encrypted_pii
    end

    def fetch
      encrypted_pii = user_session[:encrypted_pii]
      return unless encrypted_pii
      decrypted_pii = encryptor.decrypt(encrypted_pii)
      Pii::Attributes.new_from_json(decrypted_pii)
    end

    private

    attr_reader :user, :user_session

    def key_maker
      Pii::KeyMaker.new
    end

    def encryptor
      Pii::EnvelopeEncryptor.new
    end
  end
end
