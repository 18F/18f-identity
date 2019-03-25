module RecoveryHelper
  def complete_recovery_steps_before_recover_step(user = user_with_2fa)
    dc = Recover::CreateRecoverRequest.call(user.id)
    visit idv_recovery_recover_step(dc.request_token)
    dc.request_token
  end

  def complete_recovery_steps_before_welcome_step(user = user_with_2fa)
    complete_recovery_steps_before_recover_step(user)
    click_idv_continue
  end

  def complete_recovery_steps_before_upload_step(user = user_with_2fa)
    complete_recovery_steps_before_welcome_step(user)
    click_on t('doc_auth.buttons.get_started')
  end

  def complete_recovery_steps_before_front_image_step(user = user_with_2fa)
    complete_recovery_steps_before_upload_step(user)
    click_on t('doc_auth.buttons.use_computer')
  end

  def complete_recovery_steps_before_back_image_step(user = user_with_2fa)
    complete_recovery_steps_before_front_image_step(user)
    mock_assure_id_ok
    attach_image
    click_idv_continue
  end

  def idv_recovery_recover_step(token)
    idv_recovery_step_path(step: :recover, token: token)
  end

  def idv_recovery_welcome_step
    idv_recovery_step_path(step: :welcome)
  end

  def idv_recovery_upload_step
    idv_recovery_step_path(step: :upload)
  end

  def idv_recovery_front_image_step
    idv_recovery_step_path(step: :front_image)
  end

  def idv_recovery_back_image_step
    idv_recovery_step_path(step: :back_image)
  end

  def idv_recovery_ssn_step
    idv_recovery_step_path(step: :ssn)
  end
end
