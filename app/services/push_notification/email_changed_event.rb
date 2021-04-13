module PushNotification
  class EmailChangedEvent
    EVENT_TYPE = 'https://schemas.openid.net/secevent/risc/event-type/identifier-changed'.freeze

    attr_reader :user, :email

    def initialize(user:, email:)
      @user = user
      @email = email
    end

    def event_type
      EVENT_TYPE
    end

    def payload(*)
      {
        subject: {
          subject_type: 'email',
          email: email.email,
        },
      }
    end
  end
end