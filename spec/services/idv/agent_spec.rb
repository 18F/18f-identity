require 'rails_helper'
require 'ostruct'

describe Idv::Agent do
  let(:bad_phone) do
    IdentityIdpFunctions::AddressMockClient::UNVERIFIABLE_PHONE_NUMBER
  end

  describe 'instance' do
    let(:applicant) { { foo: 'bar' } }
    let(:trace_id) { SecureRandom.uuid }

    let(:agent) { Idv::Agent.new(applicant) }

    describe '#proof_resolution' do
      let(:document_capture_session) { DocumentCaptureSession.new(result_id: SecureRandom.hex) }

      context 'proofing state_id enabled' do
        it 'does not proof state_id if resolution fails' do
          agent = Idv::Agent.new({ ssn: '444-55-6666', first_name: Faker::Name.first_name,
                                   zipcode: '11111' })
          agent.proof_resolution(
            document_capture_session, should_proof_state_id: true, trace_id: trace_id
          )
          result = document_capture_session.load_proofing_result.result
          expect(result[:errors][:ssn]).to eq ['Unverified SSN.']
          expect(result[:context][:stages]).to_not include(
            state_id: 'StateIdMock',
            transaction_id: IdentityIdpFunctions::StateIdMockClient::TRANSACTION_ID,
          )
        end

        it 'does proof state_id if resolution succeeds' do
          agent = Idv::Agent.new(
            ssn: '444-55-8888',
            first_name: Faker::Name.first_name,
            zipcode: '11111',
            state_id_number: '123456789',
            state_id_type: 'drivers_license',
            state_id_jurisdiction: 'MD',
          )
          agent.proof_resolution(
            document_capture_session, should_proof_state_id: true, trace_id: trace_id
          )
          result = document_capture_session.load_proofing_result.result
          expect(result[:context][:stages]).to include(
            state_id: 'StateIdMock',
            transaction_id: IdentityIdpFunctions::StateIdMockClient::TRANSACTION_ID,
          )
        end

        context 'proofing partial date of birth' do
          before do
            allow(AppConfig.env).to receive(:proofing_send_partial_dob).and_return('true')
          end

          it 'passes dob_year_only to the proofing function' do
            expect(LambdaJobs::Runner).to receive(:new).
              with(hash_including(args: hash_including(dob_year_only: true))).
              and_call_original

            agent.proof_resolution(
              document_capture_session, should_proof_state_id: true, trace_id: trace_id
            )
          end
        end
      end

      context 'proofing state_id disabled' do
        it 'does not proof state_id if resolution fails' do
          agent = Idv::Agent.new({ ssn: '444-55-6666', first_name: Faker::Name.first_name,
                                   zipcode: '11111' })
          agent.proof_resolution(
            document_capture_session, should_proof_state_id: true, trace_id: trace_id
          )
          result = document_capture_session.load_proofing_result.result
          expect(result[:errors][:ssn]).to eq ['Unverified SSN.']
          expect(result[:context][:stages]).to_not include(
            state_id: 'StateIdMock',
            transaction_id: IdentityIdpFunctions::StateIdMockClient::TRANSACTION_ID,
          )
        end

        it 'does not proof state_id if resolution succeeds' do
          agent = Idv::Agent.new({ ssn: '444-55-8888', first_name: Faker::Name.first_name,
                                   zipcode: '11111' })
          agent.proof_resolution(
            document_capture_session, should_proof_state_id: false, trace_id: trace_id
          )
          result = document_capture_session.load_proofing_result.result
          expect(result[:context][:stages]).to_not include(
            state_id: 'StateIdMock',
            transaction_id: IdentityIdpFunctions::StateIdMockClient::TRANSACTION_ID,
          )
        end
      end

      it 'returns an unsuccessful result and notifies exception trackers if an exception occurs' do
        agent = Idv::Agent.new(ssn: '444-55-8888', first_name: 'Time Exception',
                               zipcode: '11111')

        agent.proof_resolution(
          document_capture_session, should_proof_state_id: true, trace_id: trace_id
        )
        result = document_capture_session.load_proofing_result.result

        expect(result[:exception]).to start_with('#<Proofer::TimeoutError: ')
        expect(result).to include(
          success: false,
          timed_out: true,
        )
      end

      it 'passes the right lexisnexis configs' do
        expect(LambdaJobs::Runner).to receive(:new).and_wrap_original do |impl, args|
          lexisnexis_config = args.dig(:in_process_config, :lexisnexis_config)
          expect(lexisnexis_config).to include(:instant_verify_workflow)
          expect(lexisnexis_config).to_not include(:phone_finder_workflow)

          impl.call(args)
        end

        agent.proof_resolution(
          document_capture_session, should_proof_state_id: true, trace_id: trace_id
        )
      end
    end

    describe '#proof_address' do
      let(:document_capture_session) { DocumentCaptureSession.new(result_id: SecureRandom.hex) }

      it 'proofs addresses successfully with valid information' do
        agent = Idv::Agent.new({ phone: Faker::PhoneNumber.cell_phone })
        agent.proof_address(document_capture_session, trace_id: trace_id)
        result = document_capture_session.load_proofing_result[:result]
        expect(result[:context][:stages]).to include({ address: 'AddressMock' })
        expect(result[:success]).to eq true
      end

      it 'fails to proof addresses with invalid information' do
        agent = Idv::Agent.new(phone: bad_phone)
        agent.proof_address(document_capture_session, trace_id: trace_id)
        result = document_capture_session.load_proofing_result[:result]
        expect(result[:context][:stages]).to include({ address: 'AddressMock' })
        expect(result[:success]).to eq false
      end

      it 'passes the right lexisnexis configs' do
        expect(LambdaJobs::Runner).to receive(:new).and_wrap_original do |impl, args|
          lexisnexis_config = args.dig(:in_process_config, :lexisnexis_config)
          expect(lexisnexis_config).to_not include(:instant_verify_workflow)
          expect(lexisnexis_config).to include(:phone_finder_workflow)

          impl.call(args)
        end

        agent.proof_address(document_capture_session, trace_id: trace_id)
      end
    end
  end
end
