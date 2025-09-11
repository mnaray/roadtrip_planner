require 'rails_helper'

RSpec.describe PackingList, type: :model do
  describe 'associations' do
    it 'belongs to a road trip' do
      expect(PackingList.reflect_on_association(:road_trip).macro).to eq(:belongs_to)
    end

    it 'has many packing list items with dependent destroy' do
      expect(PackingList.reflect_on_association(:packing_list_items).macro).to eq(:has_many)
      expect(PackingList.reflect_on_association(:packing_list_items).options[:dependent]).to eq(:destroy)
    end
  end

  describe 'validations' do
    subject { build(:packing_list) }

    it 'validates presence of name' do
      subject.name = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to include("can't be blank")
    end

    it 'validates length of name' do
      subject.name = ""
      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to include("is too short (minimum is 1 character)")

      subject.name = "a" * 101
      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to include("is too long (maximum is 100 characters)")

      subject.name = "Valid Packing List"
      expect(subject).to be_valid
    end
  end

  describe '#total_items_count' do
    let(:packing_list) { create(:packing_list) }

    it 'returns 0 for no items' do
      expect(packing_list.total_items_count).to eq(0)
    end

    it 'returns the sum of all item quantities' do
      create(:packing_list_item, packing_list: packing_list, quantity: 3)
      create(:packing_list_item, packing_list: packing_list, quantity: 2)
      create(:packing_list_item, packing_list: packing_list, quantity: 1)

      expect(packing_list.total_items_count).to eq(6)
    end
  end

  describe '#packed_items_count' do
    let(:packing_list) { create(:packing_list) }

    it 'returns 0 for no packed items' do
      create(:packing_list_item, packing_list: packing_list, packed: false, quantity: 3)
      expect(packing_list.packed_items_count).to eq(0)
    end

    it 'returns the sum of packed item quantities' do
      create(:packing_list_item, packing_list: packing_list, packed: true, quantity: 3)
      create(:packing_list_item, packing_list: packing_list, packed: false, quantity: 2)
      create(:packing_list_item, packing_list: packing_list, packed: true, quantity: 1)

      expect(packing_list.packed_items_count).to eq(4)
    end
  end

  describe '#packing_progress' do
    let(:packing_list) { create(:packing_list) }

    it 'returns 0 for no items' do
      expect(packing_list.packing_progress).to eq(0)
    end

    it 'calculates percentage correctly' do
      create(:packing_list_item, packing_list: packing_list, packed: true, quantity: 2)
      create(:packing_list_item, packing_list: packing_list, packed: false, quantity: 8)

      expect(packing_list.packing_progress).to eq(20.0)
    end

    it 'returns 100 when all items are packed' do
      create(:packing_list_item, packing_list: packing_list, packed: true, quantity: 2)
      create(:packing_list_item, packing_list: packing_list, packed: true, quantity: 3)

      expect(packing_list.packing_progress).to eq(100.0)
    end

    it 'rounds to one decimal place' do
      create(:packing_list_item, packing_list: packing_list, packed: true, quantity: 1)
      create(:packing_list_item, packing_list: packing_list, packed: false, quantity: 2)

      expect(packing_list.packing_progress).to eq(33.3)
    end
  end

  describe '#items_by_category' do
    let(:packing_list) { create(:packing_list) }

    it 'groups items by category' do
      clothes_item = create(:packing_list_item, packing_list: packing_list, category: "clothes")
      electronics_item = create(:packing_list_item, packing_list: packing_list, category: "electronics")
      another_clothes_item = create(:packing_list_item, packing_list: packing_list, category: "clothes")

      grouped_items = packing_list.items_by_category

      expect(grouped_items["clothes"]).to contain_exactly(clothes_item, another_clothes_item)
      expect(grouped_items["electronics"]).to contain_exactly(electronics_item)
    end

    it 'returns empty hash for no items' do
      expect(packing_list.items_by_category).to eq({})
    end
  end
end
