# Route Model

The Route model represents individual segments of a road trip journey, containing detailed location, timing, and distance information. It includes sophisticated business logic for route validation and automatic distance calculation.

## Model Definition

**File**: `app/models/route.rb`  
**Table**: `routes`  
**Primary Key**: `id` (bigint, auto-increment)

## Database Schema

```sql
CREATE TABLE routes (
  id                bigint PRIMARY KEY,
  starting_location string,
  destination      string,
  datetime         timestamp,
  road_trip_id     bigint NOT NULL REFERENCES road_trips(id),
  user_id          bigint NOT NULL REFERENCES users(id),
  distance         float,
  duration         float,
  created_at       timestamp NOT NULL,
  updated_at       timestamp NOT NULL
);

CREATE INDEX index_routes_on_road_trip_id ON routes (road_trip_id);
CREATE INDEX index_routes_on_user_id ON routes (user_id);
```

## Attributes

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | `bigint` | Primary Key, Auto-increment | Unique route identifier |
| `starting_location` | `string` | - | Starting point description |
| `destination` | `string` | - | End point description |
| `datetime` | `timestamp` | - | Departure date and time |
| `road_trip_id` | `bigint` | NOT NULL, Foreign Key | Parent trip reference |
| `user_id` | `bigint` | NOT NULL, Foreign Key | Owner reference |
| `distance` | `float` | - | Route distance in kilometers |
| `duration` | `float` | - | Route duration in hours |
| `created_at` | `timestamp` | NOT NULL | Record creation time |
| `updated_at` | `timestamp` | NOT NULL | Last modification time |

## Associations

```ruby
class Route < ApplicationRecord
  belongs_to :road_trip
  belongs_to :user
end
```

### Association Details

#### `belongs_to :road_trip`
- **Type**: Many-to-one relationship
- **Foreign Key**: `road_trip_id`
- **Required**: Yes (validates presence)
- **Usage**: `route.road_trip` returns the parent trip

#### `belongs_to :user`
- **Type**: Many-to-one relationship
- **Foreign Key**: `user_id`
- **Required**: Yes (validates presence)
- **Usage**: `route.user` returns the route creator
- **Security**: Enables user ownership validation

## Validations

### Location Validations

```ruby
validates :starting_location, 
  presence: true, 
  length: { minimum: 1, maximum: 200 }

validates :destination, 
  presence: true, 
  length: { minimum: 1, maximum: 200 }
```

**Rules**:
- Both starting location and destination are required
- Location strings must be between 1 and 200 characters
- Supports any location format (addresses, landmarks, coordinates)

### Datetime Validation

```ruby
validates :datetime, 
  presence: true, 
  unless: -> { validation_context == :location_only }
```

**Conditional Validation**:
- Datetime is required for normal route creation
- Can be skipped when validation context is `:location_only`
- Allows partial route creation for location-only workflows

### Custom Business Logic Validations

```ruby
validate :datetime_not_overlapping_with_other_routes, 
  unless: -> { validation_context == :location_only }
validate :user_matches_road_trip_user
```

## Complex Validation Logic

### Overlap Prevention

```ruby
def datetime_not_overlapping_with_other_routes
  return unless datetime && road_trip

  # Calculate end time using duration_hours which handles nil values
  my_duration = duration || 2.0
  end_time = datetime + my_duration.hours

  # Check for overlap: two time ranges [A1,A2] and [B1,B2] overlap if A1 < B2 AND A2 > B1
  overlapping_routes = road_trip.routes
    .where.not(id: id)
    .where(
      "? < datetime + (COALESCE(duration, 2.0) * INTERVAL '1 hour') AND ? > datetime",
      datetime, end_time
    )

  if overlapping_routes.exists?
    errors.add(:datetime, "overlaps with another route in this road trip")
  end
end
```

**Overlap Detection Logic**:
- Two routes overlap if one starts before the other ends
- Uses mathematical interval overlap: `A1 < B2 AND A2 > B1`
- Handles nil duration with 2-hour default
- Uses database-level calculations for precision
- Excludes current record when updating

### User Authorization Validation

```ruby
def user_matches_road_trip_user
  return unless road_trip && user

  if road_trip.user_id != user_id
    errors.add(:user, "must match the road trip's user")
  end
end
```

**Security Enforcement**:
- Ensures route creator matches trip owner
- Prevents cross-user data corruption
- Enforces data ownership consistency

## Scopes

```ruby
scope :for_user, ->(user) { where(user: user) }
scope :ordered_by_datetime, -> { order(:datetime) }
```

### Available Scopes

#### `:for_user`
- **Purpose**: Filter routes by user ownership
- **Usage**: `Route.for_user(current_user)`
- **Security**: Ensures users only see their own routes

#### `:ordered_by_datetime`
- **Purpose**: Sort routes by departure time
- **Usage**: `trip.routes.ordered_by_datetime`
- **Use Case**: Chronological route display

## Business Logic Methods

### Duration Access with Fallback

```ruby
def duration_hours
  # Return stored duration if available, otherwise default to 2 hours
  # Avoid expensive API calls during validation
  duration || 2.0
end
```

**Features**:
- Provides safe access to duration with fallback
- Prevents nil values in calculations
- Uses 2-hour default for reasonable estimates
- Optimized for validation performance

### Distance Calculation

```ruby
def distance_in_km
  distance || calculate_and_save_route_metrics[:distance]
end
```

**Lazy Loading Pattern**:
- Returns stored distance if available
- Triggers calculation only when needed
- Caches result after calculation
- Handles missing data gracefully

## Automatic Data Processing

### Route Metrics Calculation

```ruby
before_save :calculate_route_metrics, if: :locations_changed?

private

def locations_changed?
  starting_location_changed? || destination_changed?
end

def calculate_route_metrics
  return unless starting_location.present? && destination.present?

  calculator = RouteDistanceCalculator.new(starting_location, destination)
  result = calculator.calculate

  self.distance = result[:distance]
  self.duration = result[:duration]
end
```

**Automatic Processing**:
- Triggers distance calculation when locations change
- Uses service object for external API integration
- Updates both distance and duration fields
- Only processes when both locations are present

### Advanced Calculation Method

```ruby
def calculate_and_save_route_metrics
  return { distance: nil, duration: nil } unless starting_location.present? && destination.present?

  # Only calculate if we don't have both values
  if distance.nil? || duration.nil?
    calculate_route_metrics
    save if persisted? && (distance_changed? || duration_changed?)
  end

  { distance: distance, duration: duration }
end
```

**Smart Calculation**:
- Avoids redundant API calls for existing data
- Persists results automatically when record exists
- Returns current values whether calculated or cached
- Handles partial data scenarios

## Usage Examples

### Creating Routes

```ruby
# Basic route creation
route = trip.routes.create!(
  starting_location: "San Francisco, CA",
  destination: "Los Angeles, CA", 
  datetime: 1.week.from_now,
  user: current_user
)

# Route with validation context
route = Route.new(
  starting_location: "New York",
  destination: "Boston",
  road_trip: trip,
  user: current_user
)
route.save(context: :location_only)  # Skip datetime validation
```

### Data Access Patterns

```ruby
# Get routes for a user
user_routes = Route.for_user(current_user).includes(:road_trip)

# Get trip routes in chronological order
trip_routes = trip.routes.ordered_by_datetime

# Get routes with calculated distances
routes_with_distances = trip.routes.select { |r| r.distance.present? }

# Force distance calculation
route.distance_in_km  # Triggers calculation if needed
```

### Complex Queries

```ruby
# Find overlapping routes (for debugging)
overlapping_routes = Route.joins(:road_trip)
  .where(road_trips: { user: current_user })
  .where("EXISTS (
    SELECT 1 FROM routes r2 
    WHERE r2.road_trip_id = routes.road_trip_id 
    AND r2.id != routes.id
    AND routes.datetime < r2.datetime + (COALESCE(r2.duration, 2.0) * INTERVAL '1 hour')
    AND (routes.datetime + (COALESCE(routes.duration, 2.0) * INTERVAL '1 hour')) > r2.datetime
  )")

# Get routes needing distance calculation
routes_without_distance = current_user.routes
  .where(distance: nil)
  .where.not(starting_location: nil, destination: nil)
```

## Performance Optimization

### Efficient Loading

```ruby
# Preload associations to avoid N+1 queries
routes_with_trips = Route.includes(:road_trip, :user).for_user(current_user)

# Load only necessary fields
route_summaries = Route.select(:id, :starting_location, :destination, :datetime)
  .for_user(current_user)
```

### Background Processing

```ruby
# Process distance calculations in background
class CalculateRouteDistanceJob < ApplicationJob
  def perform(route_id)
    route = Route.find(route_id)
    route.calculate_and_save_route_metrics
  end
end

# Usage after route creation
CalculateRouteDistanceJob.perform_later(route.id)
```

## Testing

### Model Specs

```ruby
# spec/models/route_spec.rb
RSpec.describe Route, type: :model do
  describe 'validations' do
    subject { build(:route) }
    
    it { is_expected.to validate_presence_of(:starting_location) }
    it { is_expected.to validate_presence_of(:destination) }
    it { is_expected.to validate_length_of(:starting_location).is_at_most(200) }
    it { is_expected.to validate_length_of(:destination).is_at_most(200) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:road_trip) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'overlap validation' do
    let(:trip) { create(:road_trip) }
    let(:user) { trip.user }
    
    let!(:existing_route) do
      create(:route,
        road_trip: trip,
        user: user,
        datetime: Time.current + 1.hour,
        duration: 3.0
      )
    end

    context 'when routes overlap' do
      it 'prevents overlapping routes' do
        overlapping_route = build(:route,
          road_trip: trip,
          user: user,
          datetime: Time.current + 2.hours,  # Overlaps with existing route
          duration: 2.0
        )
        
        expect(overlapping_route).not_to be_valid
        expect(overlapping_route.errors[:datetime]).to include('overlaps with another route in this road trip')
      end
    end

    context 'when routes do not overlap' do
      it 'allows non-overlapping routes' do
        non_overlapping_route = build(:route,
          road_trip: trip,
          user: user,
          datetime: Time.current + 5.hours,  # After existing route ends
          duration: 2.0
        )
        
        expect(non_overlapping_route).to be_valid
      end
    end
  end

  describe 'user authorization validation' do
    let(:trip) { create(:road_trip) }
    let(:other_user) { create(:user) }

    it 'prevents routes from different users' do
      route = build(:route, road_trip: trip, user: other_user)
      
      expect(route).not_to be_valid
      expect(route.errors[:user]).to include('must match the road trip\'s user')
    end
  end

  describe '#duration_hours' do
    context 'with stored duration' do
      let(:route) { build(:route, duration: 4.5) }
      
      it 'returns stored duration' do
        expect(route.duration_hours).to eq(4.5)
      end
    end

    context 'without stored duration' do
      let(:route) { build(:route, duration: nil) }
      
      it 'returns default 2.0 hours' do
        expect(route.duration_hours).to eq(2.0)
      end
    end
  end

  describe '#distance_in_km' do
    context 'with stored distance' do
      let(:route) { build(:route, distance: 150.5) }
      
      it 'returns stored distance' do
        expect(route.distance_in_km).to eq(150.5)
      end
    end

    context 'without stored distance' do
      let(:route) { create(:route, distance: nil) }
      
      before do
        allow(RouteDistanceCalculator).to receive(:new).and_return(
          double(calculate: { distance: 200.0, duration: 3.5 })
        )
      end
      
      it 'triggers calculation' do
        expect(route.distance_in_km).to eq(200.0)
      end
    end
  end
end
```

### Factory Definition

```ruby
# spec/factories/routes.rb
FactoryBot.define do
  factory :route do
    starting_location { "San Francisco, CA" }
    destination { "Los Angeles, CA" }
    datetime { 1.week.from_now }
    distance { 380.5 }
    duration { 6.5 }
    
    association :road_trip
    association :user
    
    # Ensure user matches road_trip user
    after(:build) do |route|
      route.user = route.road_trip.user if route.road_trip&.user
    end

    trait :without_metrics do
      distance { nil }
      duration { nil }
    end

    trait :cross_country do
      starting_location { "New York, NY" }
      destination { "San Francisco, CA" }
      distance { 2900.0 }
      duration { 42.0 }
    end

    trait :short_trip do
      starting_location { "Downtown" }
      destination { "Airport" }
      distance { 25.0 }
      duration { 0.5 }
    end
  end
end
```

## Integration Patterns

### Controller Integration

```ruby
class RoutesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_road_trip
  before_action :set_route, only: [:show, :edit, :update, :destroy]

  def create
    @route = @road_trip.routes.build(route_params)
    @route.user = current_user
    
    if @route.save
      CalculateRouteDistanceJob.perform_later(@route.id)
      redirect_to [@road_trip, @route], notice: 'Route added successfully!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_road_trip
    @road_trip = current_user.road_trips.find(params[:road_trip_id])
  end

  def set_route
    @route = @road_trip.routes.find(params[:id])
  end

  def route_params
    params.require(:route).permit(:starting_location, :destination, :datetime)
  end
end
```

## Future Enhancements

### Planned Features

1. **Waypoints**: Intermediate stops within routes
2. **Route Notes**: Text descriptions and travel notes
3. **Route Status**: Planning/Active/Completed states
4. **Route Sharing**: Export individual routes
5. **Route Optimization**: Automatic route ordering
6. **Real-time Updates**: Live traffic and weather integration

### Database Extensions

```ruby
# Future migration for enhanced route features
class EnhanceRoutes < ActiveRecord::Migration[8.0]
  def change
    add_column :routes, :notes, :text
    add_column :routes, :status, :integer, default: 0
    add_column :routes, :waypoints, :json, default: []
    add_column :routes, :traffic_duration, :float
    add_column :routes, :weather_conditions, :json
    
    add_index :routes, :status
    add_index :routes, :traffic_duration
  end
end
```

The Route model provides sophisticated route management with automatic distance calculation, overlap prevention, and robust validation logic, forming the core of the trip planning functionality.