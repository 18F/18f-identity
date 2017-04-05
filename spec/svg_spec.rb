require 'rails_helper'

RSpec.describe 'SVG files' do
  Dir[Rails.root.join('**/*.svg')].each do |svg_path|
    relative_path = svg_path.sub(Rails.root.to_s, '')

    describe relative_path do
      it 'does not contain inline styles' do
        doc = Nokogiri::XML(File.read(svg_path))

        aggregate_failures do
          expect(doc.css('style')).to be_empty
          expect(doc.css('[style]')).to be_empty
        end
      end
    end
  end
end
