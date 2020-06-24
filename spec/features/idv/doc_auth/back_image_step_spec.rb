require 'rails_helper'

feature 'doc auth back image step' do
  include IdvStepHelper
  include DocAuthHelper

  let(:max_attempts) { Figaro.env.acuant_max_attempts.to_i }
  let(:user) { user_with_2fa }

  before do
    sign_in_and_2fa_user(user)
    complete_doc_auth_steps_before_back_image_step
  end

  it 'is on the correct page' do
    expect(page).to have_current_path(idv_doc_auth_back_image_step)
    expect(page).to have_content(t('doc_auth.headings.upload_back'))
  end

  it 'displays tips and sample images' do
    expect(page).to have_current_path(idv_doc_auth_back_image_step)
    expect(page).to have_content(I18n.t('doc_auth.tips.text1'))
    expect(page).to have_css('img[src*=state-id-sample-back]')
  end

  it 'proceeds to the next page with valid info' do
    attach_image
    click_idv_continue

    expect(page).to have_current_path(idv_doc_auth_ssn_step)
    user = User.first
    expect(user.proofing_component.document_check).to eq('acuant')
    expect(user.proofing_component.document_type).to eq('state_id')
  end

  it 'allows the use of a base64 encoded data url representation of the image' do
    acuant_client = AcuantMock::AcuantMockClient.new
    expect(AcuantMock::AcuantMockClient).to receive(:new).and_return(acuant_client)
    expect(acuant_client).to receive(:post_back_image).
      with(hash_including(image: doc_auth_image_data_url_data)).
      and_return(Acuant::Response.new(success: true))

    attach_image_data_url
    click_idv_continue

    expect(page).to have_current_path(idv_doc_auth_ssn_step)
  end

  it 'proceeds to the next page if the user does not have a phone' do
    user = create(:user, :with_authentication_app, :with_piv_or_cac)
    sign_in_and_2fa_user(user)
    complete_doc_auth_steps_before_back_image_step
    attach_image
    click_idv_continue

    expect(page).to have_current_path(idv_doc_auth_ssn_step)
  end

  it 'does not proceed to the next page if the image upload fails' do
    AcuantMock::AcuantMockClient.mock_response!(
      method: :post_back_image,
      response: Acuant::Response.new(
        success: false,
        errors: [I18n.t('errors.doc_auth.acuant_network_error')],
      ),
    )

    attach_image
    click_idv_continue

    expect(page).to have_current_path(idv_doc_auth_back_image_step)
    expect(page).to have_content(I18n.t('errors.doc_auth.acuant_network_error'))
  end

  it 'sends the user back to the front image step if the document cannot be verified' do
    mock_general_doc_auth_client_error(:get_results)

    attach_image
    click_idv_continue

    expect(page).to have_current_path(idv_doc_auth_front_image_step)
    expect(page).to have_content(I18n.t('errors.doc_auth.general_error'))
    expect(page).to have_content(strip_tags(I18n.t('errors.doc_auth.general_info'))[0..32])
  end

  it 'renders a friendly error message if one is present on the response' do
    error_message = I18n.t('friendly_errors.doc_auth.barcode_could_not_be_read')
    AcuantMock::AcuantMockClient.mock_response!(
      method: :get_results,
      response: Acuant::Response.new(
        success: false,
        errors: [error_message],
      ),
    )

    attach_image
    click_idv_continue

    expect(page).to have_current_path(idv_doc_auth_front_image_step)
    expect(page).to have_content(error_message)
  end

  it 'throttles calls to acuant and allows attempts after the attempt window' do
    (max_attempts / 2).times do
      attach_image
      click_idv_continue

      expect(page).to have_current_path(idv_doc_auth_ssn_step)

      click_on t('doc_auth.buttons.start_over')
      complete_doc_auth_steps_before_back_image_step
    end

    expect(page).to have_current_path(idv_session_errors_throttled_path)

    Timecop.travel((Figaro.env.acuant_attempt_window_in_minutes.to_i + 1).minutes.from_now) do
      sign_in_and_2fa_user(user)
      complete_doc_auth_steps_before_back_image_step
      attach_image
      click_idv_continue
      expect(page).to have_current_path(idv_doc_auth_ssn_step)
    end
  end

  # TODO: Remove this test
  xit 'notifies newrelic when acuant goes over the rack timeout' do
    allow_any_instance_of(Idv::Acuant::AssureId).to receive(:results).
      and_raise(Rack::Timeout::RequestTimeoutException.new(nil))

    attach_image

    expect(NewRelic::Agent).to receive(:notice_error) unless simulate
    click_idv_continue
  end
end
