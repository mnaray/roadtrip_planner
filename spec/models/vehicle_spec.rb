require 'rails_helper'

RSpec.describe Vehicle, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it 'belongs to a user' do
      expect(Vehicle.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it 'has one attached image' do
      vehicle = create(:vehicle, user: user)
      expect(vehicle.image).to be_an(ActiveStorage::Attached::One)
    end
  end

  describe 'validations' do
    subject { build(:vehicle, user: user) }

    it 'validates presence of name' do
      subject.name = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to include("can't be blank")
    end

    it 'validates length of name' do
      subject.name = ''
      expect(subject).not_to be_valid
      subject.name = 'a' * 101
      expect(subject).not_to be_valid
      subject.name = 'Valid Name'
      expect(subject).to be_valid
    end

    it 'validates presence of vehicle_type' do
      subject.vehicle_type = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:vehicle_type]).to include("can't be blank")
    end

    it 'validates inclusion of vehicle_type in allowed types' do
      subject.vehicle_type = 'invalid_type'
      expect(subject).not_to be_valid
      Vehicle::VEHICLE_TYPES.each do |type|
        subject.vehicle_type = type
        expect(subject).to be_valid
      end
    end

    it 'validates length of make_model' do
      subject.make_model = 'a' * 201
      expect(subject).not_to be_valid
      subject.make_model = 'Valid Make Model'
      expect(subject).to be_valid
    end

    it 'validates numericality of engine_volume_ccm' do
      subject.engine_volume_ccm = 0
      expect(subject).not_to be_valid
      subject.engine_volume_ccm = -1
      expect(subject).not_to be_valid
      subject.engine_volume_ccm = 1800
      expect(subject).to be_valid
      subject.engine_volume_ccm = nil
      expect(subject).to be_valid
    end

    it 'validates numericality of numeric fields' do
      [:horsepower, :torque, :passenger_count].each do |field|
        subject.send("#{field}=", 0)
        expect(subject).not_to be_valid
        subject.send("#{field}=", -1)
        expect(subject).not_to be_valid
        subject.send("#{field}=", 100)
        expect(subject).to be_valid
        subject.send("#{field}=", nil)
        expect(subject).to be_valid
      end
    end

    it 'validates numericality of decimal fields' do
      [:fuel_consumption, :dry_weight, :wet_weight, :load_capacity].each do |field|
        subject.send("#{field}=", 0.0)
        expect(subject).not_to be_valid
        subject.send("#{field}=", -1.0)
        expect(subject).not_to be_valid
        subject.send("#{field}=", 100.5)
        expect(subject).to be_valid
        subject.send("#{field}=", nil)
        expect(subject).to be_valid
      end
    end
  end

  describe 'scopes' do
    let!(:vehicle1) { create(:vehicle, user: user) }
    let!(:vehicle2) { create(:vehicle, user: user, is_default: true) }
    let(:other_user) { create(:user) }
    let!(:other_vehicle) { create(:vehicle, user: other_user) }

    describe '.for_user' do
      it 'returns vehicles for the specified user' do
        expect(Vehicle.for_user(user)).to contain_exactly(vehicle1, vehicle2)
      end
    end

    describe '.default_for_user' do
      it 'returns the default vehicle for the specified user' do
        expect(Vehicle.default_for_user(user)).to contain_exactly(vehicle2)
      end
    end
  end

  describe 'callbacks' do
    describe '#ensure_single_default' do
      context 'when setting a vehicle as default' do
        let!(:vehicle1) { create(:vehicle, :default, user: user) }
        let!(:vehicle2) { create(:vehicle, user: user) }

        it 'removes default status from other vehicles of the same user' do
          vehicle2.update!(is_default: true)

          expect(vehicle1.reload.is_default).to be false
          expect(vehicle2.reload.is_default).to be true
        end
      end
    end

    describe '#set_new_default_if_needed' do
      context 'when deleting the default vehicle' do
        let!(:oldest_vehicle) { create(:vehicle, user: user, created_at: 3.days.ago) }
        let!(:middle_vehicle) { create(:vehicle, user: user, created_at: 2.days.ago) }
        let!(:newest_vehicle) { create(:vehicle, user: user, created_at: 1.day.ago) }
        let!(:default_vehicle) { create(:vehicle, :default, user: user, created_at: 4.days.ago) }

        it 'sets the newest remaining vehicle as default' do
          expect { default_vehicle.destroy! }.to change { newest_vehicle.reload.is_default }.from(false).to(true)
        end

        it 'does not affect vehicles of other users' do
          other_user = create(:user)
          other_default_vehicle = create(:vehicle, :default, user: other_user)

          default_vehicle.destroy!

          expect(other_default_vehicle.reload.is_default).to be true
        end

        it 'handles case when no other vehicles exist' do
          oldest_vehicle.destroy!
          middle_vehicle.destroy!
          newest_vehicle.destroy!

          expect { default_vehicle.destroy! }.not_to raise_error
          expect(user.vehicles.count).to eq(0)
        end

        context 'when there are multiple vehicles with the same creation time' do
          let!(:vehicle_a) { create(:vehicle, user: user, created_at: Time.current) }
          let!(:vehicle_b) { create(:vehicle, user: user, created_at: Time.current) }
          let!(:default_vehicle) { create(:vehicle, :default, user: user, created_at: 1.day.ago) }

          it 'selects one of the newest vehicles as default' do
            default_vehicle.destroy!

            default_count = user.vehicles.where(is_default: true).count
            expect(default_count).to eq(1)

            new_default = user.vehicles.find_by(is_default: true)
            expect([vehicle_a.id, vehicle_b.id]).to include(new_default.id)
          end
        end
      end

      context 'when deleting a non-default vehicle' do
        let!(:default_vehicle) { create(:vehicle, :default, user: user) }
        let!(:regular_vehicle) { create(:vehicle, user: user) }

        it 'does not change the default vehicle' do
          expect { regular_vehicle.destroy! }.not_to change { default_vehicle.reload.is_default }
        end
      end
    end
  end

  describe 'instance methods' do
    let(:vehicle) { build(:vehicle, vehicle_type: 'car') }

    describe '#type_icon_class' do
      it 'returns correct icon class for car' do
        vehicle.vehicle_type = 'car'
        expect(vehicle.type_icon_class).to eq('fas fa-car')
      end

      it 'returns correct icon class for motorcycle' do
        vehicle.vehicle_type = 'motorcycle'
        expect(vehicle.type_icon_class).to eq('fas fa-motorcycle')
      end

      it 'returns correct icon class for bicycle' do
        vehicle.vehicle_type = 'bicycle'
        expect(vehicle.type_icon_class).to eq('fas fa-bicycle')
      end

      it 'returns correct icon class for skateboard' do
        vehicle.vehicle_type = 'skateboard'
        expect(vehicle.type_icon_class).to eq('fas fa-skating')
      end

      it 'returns correct icon class for scooter' do
        vehicle.vehicle_type = 'scooter'
        expect(vehicle.type_icon_class).to eq('fas fa-scooter')
      end

      it 'returns default icon class for other types' do
        vehicle.vehicle_type = 'other'
        expect(vehicle.type_icon_class).to eq('fas fa-road')
      end
    end

    describe '#display_name' do
      it 'returns the vehicle name' do
        vehicle.name = 'My Test Vehicle'
        expect(vehicle.display_name).to eq('My Test Vehicle')
      end
    end

    describe '#full_description' do
      it 'returns name when make_model is blank' do
        vehicle.name = 'My Car'
        vehicle.make_model = ''
        expect(vehicle.full_description).to eq('My Car')
      end

      it 'returns name and make_model when both are present' do
        vehicle.name = 'My Car'
        vehicle.make_model = 'Honda Civic'
        expect(vehicle.full_description).to eq('My Car - Honda Civic')
      end
    end

    describe '#has_fuel_consumption?' do
      it 'returns true when fuel consumption is present and greater than 0' do
        vehicle.fuel_consumption = 6.5
        expect(vehicle.has_fuel_consumption?).to be true
      end

      it 'returns false when fuel consumption is nil' do
        vehicle.fuel_consumption = nil
        expect(vehicle.has_fuel_consumption?).to be false
      end

      it 'returns false when fuel consumption is 0' do
        vehicle.fuel_consumption = 0
        expect(vehicle.has_fuel_consumption?).to be false
      end

      it 'returns false when fuel consumption is negative' do
        vehicle.fuel_consumption = -1.0
        expect(vehicle.has_fuel_consumption?).to be false
      end
    end
  end
end