# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#swiss_date_format' do
    let(:test_datetime) { DateTime.new(2025, 3, 15, 14, 30) }

    context 'with short format' do
      it 'returns date in DD.MM.YYYY format' do
        expect(helper.swiss_date_format(test_datetime, :short)).to eq('15.03.2025')
      end
    end

    context 'with long format' do
      it 'returns date in DD.MM.YYYY at HH:MM format' do
        expect(helper.swiss_date_format(test_datetime, :long)).to eq('15.03.2025 at 14:30')
      end
    end

    context 'with with_day format' do
      it 'returns date with day name in Swiss format' do
        expect(helper.swiss_date_format(test_datetime, :with_day)).to eq('Saturday, 15. March 2025 at 14:30')
      end
    end

    context 'with default format (defaults to :long)' do
      it 'returns date in DD.MM.YYYY at HH:MM format' do
        expect(helper.swiss_date_format(test_datetime)).to eq('15.03.2025 at 14:30')
      end
    end

    context 'with custom format' do
      it 'returns date in DD.MM.YYYY HH:MM format' do
        expect(helper.swiss_date_format(test_datetime, :custom)).to eq('15.03.2025 14:30')
      end
    end

    context 'with nil datetime' do
      it 'returns nil' do
        expect(helper.swiss_date_format(nil)).to be_nil
      end
    end
  end
end
