require 'rails_helper'

describe DocAuth::Acuant::PiiFromDoc do
  include DocAuthHelper

  subject(:pii_from_doc) { described_class.new(response_body) }
  let(:response_body) { JSON.parse(AcuantFixtures.get_results_response_success) }

  describe '#call' do
    it 'correctly parses the pii data from acuant and returns a hash' do
      results = pii_from_doc.call
      expect(results).to eq(
        first_name: 'JANE',
        middle_name: nil,
        last_name: 'DOE',
        address1: '1000 E AVENUE E',
        city: 'BISMARCK',
        state: 'ND',
        zipcode: '58501',
        dob: '04/01/1984',
        state_id_number: 'DOE-84-1165',
        state_id_jurisdiction: 'ND',
        state_id_type: 'drivers_license',
      )
    end
  end

  describe '#convert_date' do
    it 'parses and formats a date from the Acuant format' do
      expect(pii_from_doc.convert_date('/Date(449625600000)/')).to eq('04/01/1984')
    end

    it 'parses and formats negative numbers' do
      expect(pii_from_doc.convert_date('/Date(-985824000000)/')).to eq('10/06/1938')
    end

    it 'is nil for a bad format' do
      expect(pii_from_doc.convert_date('/Foobar(111111)/')).to eq(nil)
    end
  end
end
