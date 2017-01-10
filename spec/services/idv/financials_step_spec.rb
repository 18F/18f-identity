require 'rails_helper'

describe Idv::FinancialsStep do
  let(:user) { build(:user) }
  let(:idv_session) do
    idvs = Idv::Session.new({}, user)
    idvs.vendor = :mock
    idvs.resolution = Proofer::Resolution.new session_id: 'some-id'
    idvs
  end
  let(:idv_finance_form) { Idv::FinanceForm.new(idv_session.params) }

  def build_step(params)
    described_class.new(
      idv_form: idv_finance_form,
      idv_session: idv_session,
      analytics: FakeAnalytics.new,
      params: params
    )
  end

  describe '#complete' do
    it 'returns false for invalid params' do
      step = build_step(finance_type: :ccn, ccn: '1234')

      expect(step.complete).to eq false
    end

    it 'returns true for mock-happy CCN' do
      step = build_step(finance_type: :ccn, ccn: '12345678')

      expect(step.complete).to eq true
    end

    it 'returns false for mock-sad CCN' do
      step = build_step(finance_type: :ccn, ccn: '00000000')

      expect(step.complete).to eq false
    end
  end

  describe '#complete?' do
    it 'returns true for mock-happy CCN' do
      step = build_step(finance_type: :ccn, ccn: '12345678')
      step.complete

      expect(step.complete?).to eq true
    end

    it 'returns false for mock-sad CCN' do
      step = build_step(finance_type: :ccn, ccn: '00000000')
      step.complete

      expect(step.complete?).to eq false
    end
  end
end
