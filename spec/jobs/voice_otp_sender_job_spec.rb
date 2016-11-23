require 'rails_helper'
include Features::ActiveJobHelper

describe VoiceOtpSenderJob do
  describe '.perform' do
    it 'initiates the phone call to deliver the OTP', twilio: true do
      TwilioService.telephony_service = FakeVoiceCall

      VoiceOtpSenderJob.perform_now(
        code: '1234',
        phone: '555-5555',
        otp_created_at: Time.current.to_s
      )

      calls = FakeVoiceCall.calls

      expect(calls.size).to eq(1)
      call = calls.first
      expect(call.to).to eq('555-5555')
      expect(call.from).to match(/(\+19999999999|\+12222222222)/)

      code = '1234'.scan(/\d/).join(', ')
      query = Rack::Utils.parse_nested_query(URI(call.url).query)
      expect(query['Message']).to eq(t('jobs.voice_otp_sender_job.message_repeat', code: code))

      nested_query = query
      while nested_query['Options']
        nested_url = URI(nested_query['Options']['1'])
        nested_query = Rack::Utils.parse_nested_query(nested_url.query)
      end
      expect(nested_query['Message']['0']).
        to eq(t('jobs.voice_otp_sender_job.message_final', code: code))
    end

    it 'does not send if the OTP code is expired' do
      reset_job_queues
      TwilioService.telephony_service = FakeVoiceCall
      FakeVoiceCall.calls = []
      otp_expiration_period = Devise.direct_otp_valid_for

      VoiceOtpSenderJob.perform_now(
        code: '1234',
        phone: '555-5555',
        otp_created_at: otp_expiration_period.ago.to_s
      )

      calls = FakeVoiceCall.calls
      expect(calls.size).to eq(0)
      expect(ActiveJob::Base.queue_adapter.enqueued_jobs).to eq []
    end
  end
end
