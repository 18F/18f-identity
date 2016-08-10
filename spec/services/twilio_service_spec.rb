require 'rails_helper'

describe TwilioService do
  describe 'proxy configuration' do
    it 'ignores the proxy configuration if not set' do
      expect(Figaro.env).to receive(:proxy_addr).and_return(nil)
      expect(Twilio::REST::Client).to receive(:new).with(/sid(1|2)/, /token(1|2)/)

      TwilioService.new
    end

    it 'passes the proxy configuration if set' do
      expect(Figaro.env).to receive(:proxy_addr).at_least(:once).and_return('123.456.789')
      expect(Figaro.env).to receive(:proxy_port).and_return('6000')

      expect(Twilio::REST::Client).to receive(:new).with(
        /sid(1|2)/,
        /token(1|2)/,
        proxy_addr: '123.456.789',
        proxy_port: '6000'
      )

      TwilioService.new
    end
  end

  context 'when telephony is disabled' do
    before do
      expect(FeatureManagement).to receive(:telephony_disabled?).at_least(:once).and_return(true)
    end

    it 'uses NullTwilioClient' do
      expect(NullTwilioClient).to receive(:new)
      expect(Twilio::REST::Client).to_not receive(:new)

      TwilioService.new
    end

    it 'uses NullTwilioClient when proxy is set' do
      allow(Figaro.env).to receive(:proxy_addr).and_return('123.456.789')

      expect(NullTwilioClient).to receive(:new)
      expect(Twilio::REST::Client).to_not receive(:new)

      TwilioService.new
    end

    it 'does not send OTP messages', twilio: true do
      SmsSenderOtpJob.perform_now('1234', '555-5555')

      expect(MockTwilioClient.messages.size).to eq 0
    end

    it 'does not send a number change messages', twilio: true do
      SmsSenderNumberChangeJob.perform_now('555-5555')

      expect(MockTwilioClient.messages.size).to eq 0
    end
  end

  context 'when telephony is enabled' do
    before do
      expect(FeatureManagement).to receive(:telephony_disabled?).at_least(:once).and_return(false)
    end

    it 'uses a real Twilio client' do
      expect(Twilio::REST::Client).to receive(:new).with(/sid(1|2)/, /token(1|2)/)
      TwilioService.new
    end
  end

  describe '#account' do
    it 'randomly samples one of the accounts' do
      expect(TWILIO_ACCOUNTS).to include(TwilioService.new.account)
    end
  end

  describe '#place_call' do
    it 'initiates a phone call with options', twilio: true do
      service = TwilioService.new

      service.place_call(
        to: '5555555555',
        url: 'https://twimlets.com/say?merp'
      )

      calls = MockTwilioClient.calls
      expect(calls.size).to eq(1)
      msg = calls.first
      expect(msg.url).to eq('https://twimlets.com/say?merp')
    end
  end

  describe '#send_sms' do
    it 'sends an SMS from the number configured in the twilio_accounts config', twilio: true do
      expect(Twilio::REST::Client).
        to receive(:new).with(/sid(1|2)/, /token(1|2)/).and_call_original

      service = TwilioService.new
      service.send_sms(
        to: '5555555555',
        body: '!!CODE1!!'
      )

      messages = MockTwilioClient.messages
      expect(messages.size).to eq(1)
      messages.each do |msg|
        expect(msg.from).to match(/(\+19999999999|\+12222222222)/)
        expect(msg.to).to eq('5555555555')
        expect(msg.body).to eq('!!CODE1!!')
      end
    end
  end
end
