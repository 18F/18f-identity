class EmailPolicy
  def initialize(user)
    @user = EmailContext.new(user)
  end

  def can_delete_email?(email)
    return false if email.confirmed? && last_confirmed_email_address?
    return false if last_email_address?
    true
  end

  private

  def last_confirmed_email_address?
    user.confirmed_email_address_count <= 1
  end

  def last_email_address?
    user.email_address_count <= 1
  end

  attr_reader :user
end
