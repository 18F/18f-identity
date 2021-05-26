module AccountResetHealthChecker
  module_function

  # @return [HealthCheckSummary]
  def check
    rec = find_request_not_serviced_within_26_hours
    HealthCheckSummary.new(healthy: rec.nil?, result: rec)
  end

  # @api private
  def find_request_not_serviced_within_26_hours
    AccountResetRequest
      .where(
        sql,
        tvalue: Time.zone.now - IdentityConfig.store.account_reset_wait_period_days.days - 2.hours,
      )
      .order('requested_at ASC')
      .first
  end

  def sql
    <<~SQL
      cancelled_at IS NULL AND
      granted_at IS NULL AND
      requested_at < :tvalue AND
      request_token IS NOT NULL AND
      granted_token IS NULL
    SQL
  end
end
