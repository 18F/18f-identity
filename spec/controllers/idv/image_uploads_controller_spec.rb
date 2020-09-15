require 'rails_helper'

describe Idv::ImageUploadsController do
  include DocAuthHelper

  describe '#create' do
    before do
      sign_in_as_user
      controller.current_user.document_capture_sessions.create!
    end

    subject(:action) { post :create, params: params }

    let(:document_capture_session) { controller.current_user.document_capture_sessions.last }
    let(:params) do
      {
        front: DocAuthImageFixtures.document_front_image_multipart,
        back: DocAuthImageFixtures.document_back_image_multipart,
        selfie: DocAuthImageFixtures.selfie_image_multipart,
        document_capture_session_uuid: document_capture_session.uuid,
      }
    end

    context 'when document capture is not enabled' do
      before do
        allow(FeatureManagement).to receive(:document_capture_step_enabled?).and_return(false)
      end

      it 'disables the endpoint' do
        action
        expect(response).to be_not_found
      end
    end

    context 'when document capture is enabled' do
      before do
        allow(FeatureManagement).to receive(:document_capture_step_enabled?).and_return(true)
      end

      context 'when fields are missing' do
        before { params.delete(:front) }

        it 'returns error status when not provided image fields' do
          action

          json = JSON.parse(response.body, symbolize_names: true)
          expect(response.status).to eq(400)
          expect(json[:success]).to eq(false)
          expect(json[:errors]).to eq [
            { field: 'front', message: 'Please fill in this field.' },
          ]
        end
      end

      context 'when a value is not a file' do
        before { params.merge!(front: 'some string') }

        it 'returns an error' do
          action

          json = JSON.parse(response.body, symbolize_names: true)
          expect(response.status).to eq(400)
          expect(json[:errors]).to eq [
            { field: 'front', message: I18n.t('doc_auth.errors.not_a_file') },
          ]
        end

        context 'with a locale param' do
          before { params.merge!(locale: 'es') }

          it 'translates errors using the locale param' do
            action

            json = JSON.parse(response.body, symbolize_names: true)
            expect(response.status).to eq(400)
            expect(json[:errors]).to eq [
              { field: 'front', message: I18n.t('doc_auth.errors.not_a_file', locale: 'es') },
            ]
          end
        end
      end

      context 'throttling' do
        it 'returns remaining_attempts with error' do
          params.delete(:front)
          allow(Throttler::RemainingCount).to receive(:call).and_return(3)

          action

          json = JSON.parse(response.body, symbolize_names: true)
          expect(response.status).to eq(400)
          expect(json).to eq({
                               success: false,
                               errors: [{ field: 'front', message: 'Please fill in this field.' }],
                               remaining_attempts: 3,
                             })
        end

        it 'returns an error when throttled' do
          allow(Throttler::IsThrottledElseIncrement).to receive(:call).once.and_return(true)
          allow(Throttler::RemainingCount).to receive(:call).and_return(0)

          action

          json = JSON.parse(response.body, symbolize_names: true)
          expect(response.status).to eq(429)
          expect(json).to eq({
                               success: false,
                               errors: [{
                                 field: 'limit',
                                 message: I18n.t('errors.doc_auth.acuant_throttle'),
                               }],
                               remaining_attempts: 0,
                             })
        end
      end

      context 'when image upload succeeds' do
        it 'returns a successful response and modifies the session' do
          action

          json = JSON.parse(response.body, symbolize_names: true)
          expect(response.status).to eq(200)
          expect(json[:success]).to eq(true)
          expect(document_capture_session.reload.load_result.success?).to eq(true)
        end
      end

      context 'when image upload fails' do
        before do
          mock_doc_auth_acuant_error_unknown
        end

        it 'returns an error response' do
          action

          json = JSON.parse(response.body, symbolize_names: true)
          expect(response.status).to eq(400)
          expect(json[:success]).to eq(false)
          expect(json[:remaining_attempts]).to be_a_kind_of(Numeric)
          expect(json[:errors]).to eq([
            # This is the error message for the error in the response fixture
            {
              field: 'results',
              message: I18n.t('friendly_errors.doc_auth.document_type_could_not_be_determined'),
            },
          ])
        end

        context 'with active doc auth funnel' do
          before do
            Funnel::DocAuth::RegisterStep.new(
              controller.current_user.id,
              'issuer',
            ).call('welcome', :view, true)
          end

          it 'logs the last doc auth error' do
            action

            expect(DocAuthLog.first.last_document_error).to eq('Unknown')
          end
        end

        context 'without active doc auth funnel' do
          it 'does not log' do
            action

            expect(DocAuthLog.count).to eq(0)
          end
        end
      end

      context 'when a value is an error-formatted yaml file' do
        before { params.merge!(back: DocAuthImageFixtures.error_yaml_multipart) }

        it 'returns error from yaml file' do
          action

          json = JSON.parse(response.body, symbolize_names: true)
          expect(json[:remaining_attempts]).to be_a_kind_of(Numeric)
          expect(json[:errors]).to eq [
            {
              field: 'results',
              message: I18n.t('friendly_errors.doc_auth.barcode_could_not_be_read'),
            },
          ]
        end
      end
    end
  end
end
