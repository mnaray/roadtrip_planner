require 'rails_helper'

RSpec.describe PackingList, type: :model do
  describe 'associations' do
    it 'belongs to a road trip' do
      expect(PackingList.reflect_on_association(:road_trip).macro).to eq(:belongs_to)
    end

    it 'belongs to a user' do
      expect(PackingList.reflect_on_association(:user).macro).to eq(:belongs_to)
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

    it 'validates presence of visibility' do
      subject.visibility = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:visibility]).to include("can't be blank")
    end

    it 'validates visibility inclusion' do
      subject.visibility = 'invalid'
      expect(subject).not_to be_valid
      expect(subject.errors[:visibility]).to include("is not included in the list")

      subject.visibility = 'private'
      expect(subject).to be_valid

      subject.visibility = 'public'
      expect(subject).to be_valid
    end

    it 'defaults to private visibility in database' do
      packing_list = create(:packing_list)
      expect(packing_list.visibility).to eq('private')
    end
  end

  describe '#total_items_count' do
    let(:packing_list) { create(:packing_list) }

    it 'returns 0 for no items' do
      expect(packing_list.total_items_count).to eq(0)
    end

    it 'returns the sum of all required item quantities' do
      create(:packing_list_item, packing_list: packing_list, quantity: 3, optional: false)
      create(:packing_list_item, packing_list: packing_list, quantity: 2, optional: false)
      create(:packing_list_item, packing_list: packing_list, quantity: 1, optional: false)

      expect(packing_list.total_items_count).to eq(6)
    end

    it 'excludes optional items from count' do
      create(:packing_list_item, packing_list: packing_list, quantity: 3, optional: false)
      create(:packing_list_item, packing_list: packing_list, quantity: 2, optional: true)
      create(:packing_list_item, packing_list: packing_list, quantity: 1, optional: false)

      expect(packing_list.total_items_count).to eq(4)
    end
  end

  describe '#packed_items_count' do
    let(:packing_list) { create(:packing_list) }

    it 'returns 0 for no packed items' do
      create(:packing_list_item, packing_list: packing_list, packed: false, quantity: 3, optional: false)
      expect(packing_list.packed_items_count).to eq(0)
    end

    it 'returns the sum of packed required item quantities' do
      create(:packing_list_item, packing_list: packing_list, packed: true, quantity: 3, optional: false)
      create(:packing_list_item, packing_list: packing_list, packed: false, quantity: 2, optional: false)
      create(:packing_list_item, packing_list: packing_list, packed: true, quantity: 1, optional: false)

      expect(packing_list.packed_items_count).to eq(4)
    end

    it 'excludes optional items from packed count' do
      create(:packing_list_item, packing_list: packing_list, packed: true, quantity: 3, optional: false)
      create(:packing_list_item, packing_list: packing_list, packed: true, quantity: 2, optional: true)
      create(:packing_list_item, packing_list: packing_list, packed: true, quantity: 1, optional: false)

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
      create(:packing_list_item, packing_list: packing_list, packed: true, quantity: 1, optional: false)
      create(:packing_list_item, packing_list: packing_list, packed: false, quantity: 2, optional: false)

      expect(packing_list.packing_progress).to eq(33.3)
    end

    it 'excludes optional items from progress calculation' do
      create(:packing_list_item, packing_list: packing_list, packed: true, quantity: 2, optional: false)
      create(:packing_list_item, packing_list: packing_list, packed: false, quantity: 2, optional: false)
      create(:packing_list_item, packing_list: packing_list, packed: true, quantity: 5, optional: true)
      create(:packing_list_item, packing_list: packing_list, packed: false, quantity: 3, optional: true)

      # Progress should be 50% (2 packed / 4 total required items)
      expect(packing_list.packing_progress).to eq(50.0)
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

  describe 'scopes' do
    it 'visible_to_user returns correct lists' do
      user1 = create(:user, username: 'testuser1')
      user2 = create(:user, username: 'testuser2')
      road_trip = create(:road_trip, user: user1)

      # Create lists directly with SQL-level attributes to avoid factory issues
      private_user1 = PackingList.create!(
        name: "Private by user1",
        visibility: "private",
        road_trip: road_trip,
        user: user1
      )
      public_user1 = PackingList.create!(
        name: "Public by user1",
        visibility: "public",
        road_trip: road_trip,
        user: user1
      )
      private_user2 = PackingList.create!(
        name: "Private by user2",
        visibility: "private",
        road_trip: road_trip,
        user: user2
      )
      public_user2 = PackingList.create!(
        name: "Public by user2",
        visibility: "public",
        road_trip: road_trip,
        user: user2
      )

      # Test user1 sees their own lists + all public lists
      visible_to_user1 = road_trip.packing_lists.visible_to_user(user1)
      expect(visible_to_user1).to contain_exactly(private_user1, public_user1, public_user2)

      # Test user2 sees public lists by user1 and all their own lists
      visible_to_user2 = road_trip.packing_lists.visible_to_user(user2)
      expect(visible_to_user2).to contain_exactly(public_user1, private_user2, public_user2)
    end

    it 'public_lists scope returns only public lists' do
      user = create(:user)
      road_trip = create(:road_trip, user: user)

      private_list = PackingList.create!(name: "Private", visibility: "private", road_trip: road_trip, user: user)
      public_list = PackingList.create!(name: "Public", visibility: "public", road_trip: road_trip, user: user)

      public_lists = road_trip.packing_lists.public_lists
      expect(public_lists).to contain_exactly(public_list)
    end

    it 'private_lists scope returns only private lists' do
      user = create(:user)
      road_trip = create(:road_trip, user: user)

      private_list = PackingList.create!(name: "Private", visibility: "private", road_trip: road_trip, user: user)
      public_list = PackingList.create!(name: "Public", visibility: "public", road_trip: road_trip, user: user)

      private_lists = road_trip.packing_lists.private_lists
      expect(private_lists).to contain_exactly(private_list)
    end
  end

  describe 'visibility methods' do
    let(:private_list) { create(:packing_list, :private_list) }
    let(:public_list) { create(:packing_list, :public_list) }

    describe '#private?' do
      it 'returns true for private lists' do
        expect(private_list.private?).to be true
      end

      it 'returns false for public lists' do
        expect(public_list.private?).to be false
      end
    end

    describe '#public?' do
      it 'returns true for public lists' do
        expect(public_list.public?).to be true
      end

      it 'returns false for private lists' do
        expect(private_list.public?).to be false
      end
    end
  end

  describe 'ownership methods' do
    let(:owner) { create(:user) }
    let(:other_user) { create(:user) }
    let(:packing_list) { create(:packing_list, user: owner) }

    describe '#owned_by?' do
      it 'returns true for the owner' do
        expect(packing_list.owned_by?(owner)).to be true
      end

      it 'returns false for other users' do
        expect(packing_list.owned_by?(other_user)).to be false
      end
    end

    describe '#visible_to?' do
      context 'private list' do
        let(:private_list) { create(:packing_list, :private_list, user: owner) }

        it 'is visible to the owner' do
          expect(private_list.visible_to?(owner)).to be true
        end

        it 'is not visible to other users' do
          expect(private_list.visible_to?(other_user)).to be false
        end
      end

      context 'public list' do
        let(:public_list) { create(:packing_list, :public_list, user: owner) }

        it 'is visible to the owner' do
          expect(public_list.visible_to?(owner)).to be true
        end

        it 'is visible to other users' do
          expect(public_list.visible_to?(other_user)).to be true
        end
      end
    end
  end
end
