require Rails.root.join('lib', 'config_validator.rb')

AppConfig.require_keys(
  %w[
    acuant_max_attempts
    acuant_attempt_window_in_minutes
    async_wait_timeout_seconds
    attribute_encryption_key
    database_statement_timeout
    disallow_all_web_crawlers
    database_name
    database_host
    database_password
    database_username
    domain_name
    enable_rate_limiting
    enable_test_routes
    enable_usps_verification
    exception_recipients
    hmac_fingerprinter_key
    idv_attempt_window_in_hours
    idv_max_attempts
    idv_send_link_attempt_window_in_minutes
    idv_send_link_max_attempts
    issuers_with_email_nameid_format
    logins_per_ip_limit
    logins_per_ip_period
    logins_per_ip_track_only_mode
    logins_per_email_and_ip_bantime
    logins_per_email_and_ip_limit
    logins_per_email_and_ip_period
    max_mail_events
    max_mail_events_window_in_days
    min_password_score
    mx_timeout
    newrelic_license_key
    otp_delivery_blocklist_findtime
    otp_delivery_blocklist_maxretry
    otp_valid_for
    password_max_attempts
    password_pepper
    rack_timeout_service_timeout_seconds
    reauthn_window
    recovery_code_length
    recurring_jobs_disabled_names
    redis_url
    reg_confirmed_email_max_attempts
    reg_confirmed_email_window_in_minutes
    reg_unconfirmed_email_max_attempts
    reg_unconfirmed_email_window_in_minutes
    requests_per_ip_limit
    requests_per_ip_period
    requests_per_ip_track_only_mode
    remember_device_expiration_hours_aal_1
    remember_device_expiration_hours_aal_2
    reset_password_email_max_attempts
    reset_password_email_window_in_minutes
    saml_endpoint_configs
    s3_report_bucket_prefix
    s3_reports_enabled
    scrypt_cost
    secret_key_base
    session_encryption_key
    session_timeout_in_minutes
    use_kms
  ],
)

ConfigValidator.new.validate(AppConfig.env.config)
