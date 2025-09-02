# RoadTrip Model

The RoadTrip model represents a complete trip plan that organizes multiple routes into a cohesive journey. It serves as the primary container for trip planning and provides aggregation functionality for trip statistics.

## Model Definition

**File**: `app/models/road_trip.rb`  
**Table**: `road_trips`  
**Primary Key**: `id` (bigint, auto-increment)

## Database Schema

```sql
CREATE TABLE road_trips (
  id         bigint PRIMARY KEY,
  name       string,
  user_id    bigint NOT NULL REFERENCES users(id),
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL
);

CREATE INDEX index_road_trips_on_user_id ON road_trips (user_id);
```

## Attributes

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | `bigint` | Primary Key, Auto-increment | Unique road trip identifier |
| `name` | `string` | - | Trip name/title |
| `user_id` | `bigint` | NOT NULL, Foreign Key | Owner reference to users table |
| `created_at` | `timestamp` | NOT NULL | Record creation time |
| `updated_at` | `timestamp` | NOT NULL | Last modification time |

## Associations

```ruby
class RoadTrip < ApplicationRecord
  belongs_to :user
  has_many :routes, dependent: :destroy
end
```

### Association Details

#### `belongs_to :user`
- **Type**: Many-to-one relationship
- **Foreign Key**: `user_id`
- **Required**: Yes (validates presence)
- **Usage**: `road_trip.user` returns the trip owner

#### `has_many :routes`
- **Type**: One-to-many relationship
- **Foreign Key**: `road_trip_id` in `routes` table
- **Dependent**: `:destroy` - Deletes all routes when trip is deleted
- **Usage**: `road_trip.routes` returns all route segments in the trip

## Validations

```ruby
class RoadTrip < ApplicationRecord
  validates :name, presence: true, length: { minimum: 1, maximum: 100 }
end
```

### Validation Rules

- **Name presence**: Trip must have a name
- **Name length**: Between 1 and 100 characters
- **User association**: Must belong to a valid user (enforced by `belongs_to`)

## Scopes

```ruby
class RoadTrip < ApplicationRecord
  scope :for_user, ->(user) { where(user: user) }
end
```

### Available Scopes

#### `:for_user`
- **Purpose**: Filter trips by user ownership
- **Usage**: `RoadTrip.for_user(current_user)`
- **Security**: Ensures users only see their own trips

## Business Logic Methods

### Distance Calculation

```ruby
def total_distance
  routes.sum { |route| route.distance_in_km.to_f }.round(1)
end
```

**Features**:
- Sums distances from all routes in the trip
- Handles nil distances gracefully (converts to 0.0)
- Returns rounded result to 1 decimal place
- Unit: kilometers

### Trip Duration Calculation

```ruby
def day_count
  return 0 if routes.empty?
  return 1 if routes.count == 1

  sorted_routes = routes.order(:datetime)
  start_date = sorted_routes.first.datetime.to_date
  end_date = sorted_routes.last.datetime.to_date
  (end_date - start_date).to_i + 1
end
```

**Logic**:
- Returns 0 for trips with no routes
- Returns 1 for single-route trips
- Calculates span between first and last route dates
- Includes both start and end dates in count
- Handles multi-day trips with proper date arithmetic

## Usage Examples

### Creating Road Trips

```ruby
# Basic trip creation
trip = current_user.road_trips.create!(
  name: "Summer Road Trip 2024"
)

# Trip with validation handling
trip = current_user.road_trips.build(name: params[:name])
if trip.save
  redirect_to trip
else
  render :new, locals: { trip: trip }
end
```

### Adding Routes to Trips

```ruby
# Add a route to an existing trip
trip = current_user.road_trips.find(params[:id])
route = trip.routes.create!(
  starting_location: "San Francisco, CA",
  destination: "Los Angeles, CA",
  datetime: 1.week.from_now,
  user: current_user
)
```

### Trip Statistics

```ruby
trip = RoadTrip.find(1)

# Get total distance for the trip
total_km = trip.total_distance
puts "Trip distance: #{total_km} km"

# Get duration in days
days = trip.day_count
puts "Trip duration: #{days} days"

# Get route count
route_count = trip.routes.count
puts "Number of routes: #{route_count}"
```

### Data Access Patterns

```ruby
# Load trip with routes (avoid N+1 queries)
trip_with_routes = RoadTrip.includes(:routes).find(id)

# Get user's recent trips
recent_trips = current_user.road_trips
  .order(created_at: :desc)
  .limit(10)

# Find trips with routes in date range
trips_in_range = current_user.road_trips
  .joins(:routes)
  .where(routes: { datetime: 1.month.ago..1.month.from_now })
  .distinct
```

## Performance Optimization

### Efficient Queries

```ruby
# Preload associations to avoid N+1 queries
trips_with_data = RoadTrip.includes(:routes, :user).for_user(current_user)

# Use database aggregations for statistics
class RoadTrip < ApplicationRecord
  # Add a counter cache for routes
  def routes_count
    routes.count
  end
  
  # Efficient distance calculation using database
  def total_distance_sql
    routes.sum(:distance) || 0.0
  end
end
```

### Caching Strategies

```ruby
# Cache expensive calculations
def total_distance
  Rails.cache.fetch("road_trip_#{id}_total_distance", expires_in: 1.hour) do
    routes.sum { |route| route.distance_in_km.to_f }.round(1)
  end
end

# Cache invalidation on route changes
class Route < ApplicationRecord
  after_save :invalidate_trip_cache
  after_destroy :invalidate_trip_cache
  
  private
  
  def invalidate_trip_cache
    Rails.cache.delete("road_trip_#{road_trip_id}_total_distance")
  end
end
```

## Security and Authorization

### Access Control

```ruby
# Controller authorization pattern
class RoadTripsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_road_trip, only: [:show, :edit, :update, :destroy]
  before_action :authorize_road_trip!, only: [:show, :edit, :update, :destroy]

  private

  def set_road_trip
    @road_trip = RoadTrip.find(params[:id])
  end

  def authorize_road_trip!
    redirect_to root_path unless @road_trip.user == current_user
  end
end
```

### Data Scope Security

```ruby
# Always scope trips to current user
class RoadTripsController < ApplicationController
  def index
    @road_trips = current_user.road_trips.includes(:routes)
  end

  def show
    @road_trip = current_user.road_trips.find(params[:id])
  end
end
```

## Testing

### Model Specs

```ruby
# spec/models/road_trip_spec.rb
RSpec.describe RoadTrip, type: :model do
  describe 'validations' do
    subject { build(:road_trip) }
    
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_least(1).is_at_most(100) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:routes).dependent(:destroy) }
  end

  describe '#total_distance' do
    let(:trip) { create(:road_trip) }
    
    context 'with no routes' do
      it 'returns 0.0' do
        expect(trip.total_distance).to eq(0.0)
      end
    end

    context 'with routes' do
      before do
        create(:route, road_trip: trip, distance: 150.5)
        create(:route, road_trip: trip, distance: 200.3)
      end

      it 'sums route distances' do
        expect(trip.total_distance).to eq(350.8)
      end
    end
  end

  describe '#day_count' do
    let(:trip) { create(:road_trip) }

    context 'with no routes' do
      it 'returns 0' do
        expect(trip.day_count).to eq(0)
      end
    end

    context 'with single route' do
      before do
        create(:route, road_trip: trip, datetime: 1.day.from_now)
      end

      it 'returns 1' do
        expect(trip.day_count).to eq(1)
      end
    end

    context 'with multiple routes over several days' do
      before do
        create(:route, road_trip: trip, datetime: Date.current)
        create(:route, road_trip: trip, datetime: 2.days.from_now)
        create(:route, road_trip: trip, datetime: 4.days.from_now)
      end

      it 'calculates total days including start and end' do
        expect(trip.day_count).to eq(5) # Day 0, 2, 4 = 5 days total
      end
    end
  end

  describe 'scopes' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let!(:trip1) { create(:road_trip, user: user1) }
    let!(:trip2) { create(:road_trip, user: user2) }

    describe '.for_user' do
      it 'returns only trips for specified user' do
        trips = RoadTrip.for_user(user1)
        expect(trips).to include(trip1)
        expect(trips).not_to include(trip2)
      end
    end
  end
end
```

### Factory Definition

```ruby
# spec/factories/road_trips.rb
FactoryBot.define do
  factory :road_trip do
    sequence(:name) { |n| "Road Trip #{n}" }
    association :user

    trait :with_routes do
      after(:create) do |road_trip|
        create_list(:route, 3, road_trip: road_trip, user: road_trip.user)
      end
    end

    trait :cross_country do
      name { "Cross Country Adventure" }
      
      after(:create) do |road_trip|
        create(:route, 
          road_trip: road_trip,
          user: road_trip.user,
          starting_location: "New York, NY",
          destination: "Chicago, IL",
          datetime: 1.week.from_now
        )
        create(:route,
          road_trip: road_trip,
          user: road_trip.user,
          starting_location: "Chicago, IL", 
          destination: "Denver, CO",
          datetime: 1.week.from_now + 1.day
        )
      end
    end
  end
end
```

## Integration Patterns

### Controller Actions

```ruby
class RoadTripsController < ApplicationController
  def index
    @road_trips = current_user.road_trips
      .includes(:routes)
      .order(created_at: :desc)
      .page(params[:page])
  end

  def show
    @road_trip = current_user.road_trips
      .includes(routes: :user)
      .find(params[:id])
  end

  def create
    @road_trip = current_user.road_trips.build(road_trip_params)
    
    if @road_trip.save
      redirect_to @road_trip, notice: 'Trip created successfully!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def road_trip_params
    params.require(:road_trip).permit(:name)
  end
end
```

### Component Integration

```ruby
# Phlex component for trip display
class TripCardComponent < ApplicationComponent
  def initialize(trip:)
    @trip = trip
  end

  def view_template
    div(class: "bg-white rounded-lg shadow-md p-6") do
      h3(class: "text-lg font-semibold mb-2") { @trip.name }
      
      div(class: "text-sm text-gray-600 space-y-1") do
        p { "#{@trip.routes.count} routes" }
        p { "#{@trip.total_distance} km total distance" }
        p { "#{@trip.day_count} days duration" }
      end
      
      div(class: "mt-4 flex space-x-2") do
        link_to "View Details", @trip, class: "btn btn-primary"
        link_to "Edit", edit_road_trip_path(@trip), class: "btn btn-secondary"
      end
    end
  end
end
```

## Future Enhancements

### Planned Features

1. **Trip Description**: Extended text field for trip details
2. **Trip Status**: Draft/Active/Completed status tracking
3. **Trip Sharing**: Public/private visibility and sharing
4. **Trip Templates**: Save trips as reusable templates
5. **Trip Budget**: Cost estimation and expense tracking
6. **Trip Photos**: Image gallery for trip memories

### Database Extensions

```ruby
# Future migration for additional fields
class AddFieldsToRoadTrips < ActiveRecord::Migration[8.0]
  def change
    add_column :road_trips, :description, :text
    add_column :road_trips, :status, :integer, default: 0
    add_column :road_trips, :public, :boolean, default: false
    add_column :road_trips, :budget_cents, :integer
    
    add_index :road_trips, :status
    add_index :road_trips, :public
  end
end
```

The RoadTrip model provides a solid foundation for organizing travel plans while maintaining simplicity and extensibility for future enhancements.