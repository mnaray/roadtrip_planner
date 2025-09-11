require 'rails_helper'

RSpec.describe PackingListItem, type: :model do
  describe 'associations' do
    it 'belongs to a packing list' do
      expect(PackingListItem.reflect_on_association(:packing_list).macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    subject { build(:packing_list_item) }

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

      subject.name = "Valid Item Name"
      expect(subject).to be_valid
    end

    it 'validates presence of quantity' do
      subject.quantity = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:quantity]).to include("can't be blank")
    end

    it 'validates quantity is a positive integer' do
      subject.quantity = 0
      expect(subject).not_to be_valid
      expect(subject.errors[:quantity]).to include("must be greater than 0")

      subject.quantity = -1
      expect(subject).not_to be_valid
      expect(subject.errors[:quantity]).to include("must be greater than 0")

      subject.quantity = 1.5
      expect(subject).not_to be_valid
      expect(subject.errors[:quantity]).to include("must be an integer")

      subject.quantity = 5
      expect(subject).to be_valid
    end

    it 'validates presence of category' do
      subject.category = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:category]).to include("can't be blank")
    end

    it 'validates packed is boolean' do
      subject.packed = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:packed]).to include("is not included in the list")

      subject.packed = true
      expect(subject).to be_valid

      subject.packed = false
      expect(subject).to be_valid
    end
  end

  describe 'enums' do
    it 'defines category enum with correct values' do
      expected_categories = {
        "tools" => "tools",
        "clothes" => "clothes",
        "hygiene" => "hygiene",
        "electronics" => "electronics",
        "food" => "food",
        "documents" => "documents",
        "medicine" => "medicine",
        "entertainment" => "entertainment",
        "other" => "other"
      }
      expect(PackingListItem.categories).to eq(expected_categories)
    end
  end

  describe 'scopes' do
    let(:packing_list) { create(:packing_list) }
    let!(:packed_item) { create(:packing_list_item, packing_list: packing_list, packed: true) }
    let!(:unpacked_item) { create(:packing_list_item, packing_list: packing_list, packed: false) }
    let!(:clothes_item) { create(:packing_list_item, packing_list: packing_list, category: "clothes") }
    let!(:tools_item) { create(:packing_list_item, packing_list: packing_list, category: "tools") }

    describe '.packed' do
      it 'returns only packed items' do
        packed_items_from_test = packing_list.packing_list_items.packed
        expect(packed_items_from_test).to contain_exactly(packed_item)
      end
    end

    describe '.unpacked' do
      it 'returns only unpacked items' do
        unpacked_items_from_test = packing_list.packing_list_items.unpacked
        expect(unpacked_items_from_test).to contain_exactly(unpacked_item, clothes_item, tools_item)
      end
    end

    describe '.by_category' do
      it 'returns items of the specified category' do
        clothes_items_from_test = packing_list.packing_list_items.by_category("clothes")
        tools_items_from_test = packing_list.packing_list_items.by_category("tools")
        
        expect(clothes_items_from_test).to contain_exactly(clothes_item)
        expect(tools_items_from_test).to contain_exactly(tools_item)
      end
    end
  end

  describe '#toggle_packed!' do
    let(:item) { create(:packing_list_item, packed: false) }

    it 'toggles packed status from false to true' do
      expect { item.toggle_packed! }.to change { item.packed }.from(false).to(true)
    end

    it 'toggles packed status from true to false' do
      item.update!(packed: true)
      expect { item.toggle_packed! }.to change { item.packed }.from(true).to(false)
    end

    it 'persists the change to database' do
      item.toggle_packed!
      expect(item.reload.packed).to eq(true)
    end
  end
end
