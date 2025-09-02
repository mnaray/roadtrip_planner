# Programming Conventions and Patterns

This document outlines the coding standards, conventions, and patterns used throughout the Roadtrip Planner application.

## Ruby Conventions

### Code Style

We follow **Rails Omakase** RuboCop configuration with these key principles:

#### Naming Conventions

```ruby
# Classes: PascalCase
class RouteDistanceCalculator
end

# Methods and variables: snake_case
def calculate_distance_in_km
  total_distance = 0
end

# Constants: SCREAMING_SNAKE_CASE
DEFAULT_ROUTE_DURATION = 2.hours

# Private methods: prefixed with private keyword
private

def helper_method
end
```

#### Method Organization

```ruby
class Route < ApplicationRecord
  # 1. Concerns and includes
  include Validatable
  
  # 2. Constants
  DEFAULT_DURATION = 2.0
  
  # 3. Associations
  belongs_to :road_trip
  belongs_to :user
  
  # 4. Validations
  validates :starting_location, presence: true
  
  # 5. Callbacks
  before_save :calculate_route_metrics
  
  # 6. Scopes
  scope :for_user, ->(user) { where(user: user) }
  
  # 7. Public methods
  def duration_hours
    duration || DEFAULT_DURATION
  end
  
  # 8. Private methods
  private
  
  def calculate_route_metrics
    # Implementation
  end
end
```

#### String and Symbol Usage

```ruby
# Prefer symbols for keys and internal identifiers
user_params = { username: 'john', password: 'secret' }

# Use strings for user-facing text
flash[:notice] = "Route successfully created"

# Hash syntax: new style for symbol keys
config = { 
  host: 'localhost',
  port: 3000
}

# Old style only when keys are mixed types
config = { 
  :symbol_key => 'value',
  'string_key' => 'value'
}
```

### ActiveRecord Patterns

#### Model Organization

```ruby
class User < ApplicationRecord
  # Use has_secure_password for authentication
  has_secure_password
  
  # Associations with dependencies
  has_many :road_trips, dependent: :destroy
  has_many :routes, dependent: :destroy
  
  # Validations with custom messages
  validates :username, 
    presence: true,
    length: { minimum: 3 },
    uniqueness: { case_sensitive: false }
    
  validates :password,
    presence: true,
    length: { minimum: 8 },
    format: { 
      with: /\A(?=.*[a-zA-Z])(?=.*\d).*\z/,
      message: "must contain both letters and numbers" 
    }
  
  # Callbacks for data normalization
  before_save :downcase_username
  
  private
  
  def downcase_username
    self.username = username.downcase if username.present?
  end
end
```

#### Query Patterns

```ruby
# Use scopes for reusable queries
class RoadTrip < ApplicationRecord
  scope :for_user, ->(user) { where(user: user) }
  scope :recent, -> { order(created_at: :desc) }
end

# Chain scopes for complex queries
recent_trips = RoadTrip.for_user(current_user).recent.limit(10)

# Use includes for N+1 prevention
trips_with_routes = RoadTrip.includes(:routes).for_user(user)

# Use joins for filtering without loading associations
popular_trips = RoadTrip.joins(:routes).group('road_trips.id').having('count(routes.id) > 5')
```

#### Validation Patterns

```ruby
# Custom validations as private methods
class Route < ApplicationRecord
  validate :datetime_not_overlapping_with_other_routes
  validate :user_matches_road_trip_user
  
  private
  
  def datetime_not_overlapping_with_other_routes
    return unless datetime && road_trip
    
    # Clear business logic with descriptive variable names
    my_duration = duration || 2.0
    end_time = datetime + my_duration.hours
    
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
end
```

## Phlex Component Patterns

### Component Structure

```ruby
class ButtonComponent < ApplicationComponent
  # 1. Initialize with named parameters
  def initialize(text:, variant: :primary, size: :medium, **options)
    @text = text
    @variant = variant
    @size = size
    @options = options
  end

  # 2. Main template method
  def view_template
    button(**attributes) { @text }
  end

  private

  # 3. Attribute building
  def attributes
    {
      class: button_classes,
      **@options
    }
  end

  # 4. CSS class logic
  def button_classes
    [
      base_classes,
      variant_classes,
      size_classes
    ].join(' ')
  end

  def base_classes
    "inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2"
  end

  def variant_classes
    case @variant
    when :primary
      "bg-primary-600 text-white hover:bg-primary-700 focus:ring-primary-500"
    when :secondary
      "bg-gray-200 text-gray-900 hover:bg-gray-300 focus:ring-gray-500"
    when :danger
      "bg-red-600 text-white hover:bg-red-700 focus:ring-red-500"
    end
  end

  def size_classes
    case @size
    when :small
      "px-3 py-1.5 text-sm"
    when :medium
      "px-4 py-2 text-base"
    when :large
      "px-6 py-3 text-lg"
    end
  end
end
```

### Component Composition

```ruby
class CardComponent < ApplicationComponent
  # Slots pattern for flexible content areas
  def initialize(title: nil, **options)
    @title = title
    @options = options
  end

  def view_template(&block)
    div(class: card_classes) do
      header_section if @title
      content_section(&block)
      footer_section if footer_content?
    end
  end

  private

  def header_section
    div(class: "px-6 py-4 border-b border-gray-200") do
      h3(class: "text-lg font-medium text-gray-900") { @title }
    end
  end

  def content_section(&block)
    div(class: "px-6 py-4", &block)
  end

  def footer_section
    div(class: "px-6 py-3 bg-gray-50 border-t border-gray-200") do
      yield :footer if block_given?
    end
  end

  def card_classes
    "bg-white shadow rounded-lg border border-gray-200"
  end
end

# Usage in other components
class TripDetailsComponent < ApplicationComponent
  def view_template
    render CardComponent.new(title: "Trip Details") do
      p { "Trip content here" }
    end
  end
end
```

### Form Components

```ruby
class FormFieldComponent < ApplicationComponent
  def initialize(form:, field:, label:, type: :text, **options)
    @form = form
    @field = field
    @label = label
    @type = type
    @options = options
  end

  def view_template
    div(class: field_wrapper_classes) do
      label_element
      input_element
      error_messages if has_errors?
    end
  end

  private

  def label_element
    @form.label(@field, @label, class: label_classes)
  end

  def input_element
    case @type
    when :text, :email, :password
      @form.text_field(@field, **input_attributes)
    when :textarea
      @form.text_area(@field, **input_attributes)
    when :select
      @form.select(@field, @options[:choices], {}, input_attributes)
    end
  end

  def input_attributes
    {
      class: input_classes,
      **@options.except(:choices)
    }
  end

  def field_wrapper_classes
    "mb-4"
  end

  def label_classes
    "block text-sm font-medium text-gray-700 mb-1"
  end

  def input_classes
    base = "block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
    has_errors? ? "#{base} border-red-300" : base
  end

  def has_errors?
    @form.object.errors[@field].any?
  end

  def error_messages
    div(class: "mt-1 text-sm text-red-600") do
      @form.object.errors[@field].each do |error|
        p { error }
      end
    end
  end
end
```

## Service Object Patterns

### Service Organization

```ruby
# Place services in app/services/
# Name services with descriptive action: VerbNoun
class RouteDistanceCalculator
  # Result object pattern for complex returns
  Result = Data.define(:distance, :duration, :success?, :error)

  def initialize(start_location, end_location)
    @start_location = start_location
    @end_location = end_location
  end

  # Single public interface
  def calculate
    return invalid_locations_result if locations_invalid?
    
    distance = calculate_distance
    duration = calculate_duration(distance)
    
    Result.new(
      distance: distance,
      duration: duration,
      success?: true,
      error: nil
    )
  rescue StandardError => e
    Result.new(
      distance: nil,
      duration: nil,
      success?: false,
      error: e.message
    )
  end

  private

  def locations_invalid?
    @start_location.blank? || @end_location.blank?
  end

  def invalid_locations_result
    Result.new(
      distance: nil,
      duration: nil,
      success?: false,
      error: "Start and end locations are required"
    )
  end

  def calculate_distance
    # Distance calculation logic
    # Return distance in kilometers
  end

  def calculate_duration(distance_km)
    # Duration calculation logic
    # Return duration in hours
  end
end

# Usage pattern
result = RouteDistanceCalculator.new(start, destination).calculate
if result.success?
  route.update!(distance: result.distance, duration: result.duration)
else
  handle_error(result.error)
end
```

## Controller Patterns

### RESTful Controllers

```ruby
class RoadTripsController < ApplicationController
  # Use before_action for common operations
  before_action :authenticate_user!
  before_action :set_road_trip, only: [:show, :edit, :update, :destroy]
  before_action :authorize_road_trip!, only: [:show, :edit, :update, :destroy]

  def index
    @road_trips = current_user.road_trips.recent.includes(:routes)
    render RoadTripsIndexPage.new(road_trips: @road_trips)
  end

  def show
    render RoadTripDetailsPage.new(road_trip: @road_trip)
  end

  def new
    @road_trip = current_user.road_trips.build
    render RoadTripFormPage.new(road_trip: @road_trip)
  end

  def create
    @road_trip = current_user.road_trips.build(road_trip_params)
    
    if @road_trip.save
      redirect_to @road_trip, notice: 'Road trip was successfully created.'
    else
      render RoadTripFormPage.new(road_trip: @road_trip), status: :unprocessable_entity
    end
  end

  private

  def set_road_trip
    @road_trip = RoadTrip.find(params[:id])
  end

  def authorize_road_trip!
    redirect_to root_path unless @road_trip.user == current_user
  end

  def road_trip_params
    params.require(:road_trip).permit(:name, :description)
  end
end
```

### Error Handling

```ruby
class ApplicationController < ActionController::Base
  # Global error handling
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request

  private

  def not_found
    render ErrorPage.new(status: 404, message: "Page not found"), status: :not_found
  end

  def bad_request
    render ErrorPage.new(status: 400, message: "Bad request"), status: :bad_request
  end

  def authenticate_user!
    redirect_to login_path unless current_user
  end

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
end
```

## Testing Patterns

### Model Testing

```ruby
# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_length_of(:username).is_at_least(3) }
    it { is_expected.to validate_uniqueness_of(:username).case_insensitive }
  end

  describe 'associations' do
    it { is_expected.to have_many(:road_trips).dependent(:destroy) }
    it { is_expected.to have_many(:routes).dependent(:destroy) }
  end

  describe '#downcase_username' do
    it 'converts username to lowercase before saving' do
      user = create(:user, username: 'TestUser')
      expect(user.username).to eq('testuser')
    end
  end
end
```

### Component Testing

```ruby
# spec/components/button_component_spec.rb
RSpec.describe ButtonComponent, type: :component do
  describe '#view_template' do
    it 'renders a primary button' do
      component = ButtonComponent.new(text: 'Click me', variant: :primary)
      
      expect(component.view_template).to have_selector(
        'button.bg-primary-600.text-white',
        text: 'Click me'
      )
    end

    it 'applies custom attributes' do
      component = ButtonComponent.new(
        text: 'Submit',
        variant: :primary,
        data: { action: 'form#submit' }
      )
      
      expect(component.view_template).to have_selector(
        'button[data-action="form#submit"]'
      )
    end
  end
end
```

### Request Testing

```ruby
# spec/requests/road_trips_spec.rb
RSpec.describe '/road_trips', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before { sign_in(user) }

  describe 'GET /road_trips' do
    it 'displays user road trips' do
      road_trip = create(:road_trip, user: user)
      other_trip = create(:road_trip, user: other_user)

      get road_trips_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(road_trip.name)
      expect(response.body).not_to include(other_trip.name)
    end
  end

  describe 'POST /road_trips' do
    context 'with valid parameters' do
      let(:valid_params) do
        { road_trip: { name: 'Summer Vacation' } }
      end

      it 'creates a new road trip' do
        expect {
          post road_trips_path, params: valid_params
        }.to change(RoadTrip, :count).by(1)

        expect(response).to redirect_to(RoadTrip.last)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        { road_trip: { name: '' } }
      end

      it 'does not create a road trip' do
        expect {
          post road_trips_path, params: invalid_params
        }.not_to change(RoadTrip, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
```

## CSS/Tailwind Patterns

### Utility Organization

```css
/* Use @layer for organized custom styles */
@layer base {
  /* Base element styles */
  h1, h2, h3, h4, h5, h6 {
    @apply font-semibold text-gray-900;
  }
}

@layer components {
  /* Reusable component styles */
  .btn {
    @apply inline-flex items-center justify-center rounded-md font-medium transition-colors;
  }

  .btn-primary {
    @apply btn bg-primary-600 text-white hover:bg-primary-700;
  }
  
  .form-input {
    @apply block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500;
  }
}

@layer utilities {
  /* Custom utility classes */
  .text-balance {
    text-wrap: balance;
  }
}
```

### Responsive Design Patterns

```ruby
# Use consistent responsive patterns in components
def responsive_classes
  [
    # Mobile first approach
    "text-sm",           # Base size
    "md:text-base",      # Medium screens and up
    "lg:text-lg",        # Large screens and up
    "px-4 py-2",         # Base padding
    "md:px-6 md:py-3",   # Larger padding on medium+
  ].join(' ')
end
```

## Documentation Patterns

### Code Documentation

```ruby
# Use clear, descriptive comments for complex logic
class Route < ApplicationRecord
  # Validates that route datetime doesn't overlap with other routes
  # in the same road trip. Two routes overlap if:
  # route1.start < route2.end AND route1.end > route2.start
  validate :datetime_not_overlapping_with_other_routes

  # Calculates the total distance for this route using external APIs
  # Falls back to stored distance if API is unavailable
  # @return [Float] distance in kilometers
  def distance_in_km
    distance || calculate_and_save_route_metrics[:distance] || 0.0
  end
end
```

### README Patterns

```markdown
# Clear section headers
## Installation
## Usage  
## Contributing
## License

# Use code blocks with language specification
```ruby
user = User.create!(username: 'john', password: 'secret123')
```

# Include examples and use cases
### Creating a Road Trip
```ruby
trip = current_user.road_trips.create!(name: 'Summer Adventure')
```

These conventions ensure consistency, maintainability, and readability across the entire codebase. All team members should follow these patterns when contributing to the project.