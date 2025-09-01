# User Model

The User model is the cornerstone of authentication and data ownership in Roadtrip Planner. It handles secure user authentication and serves as the parent entity for all trip-related data.

## Model Definition

**File**: `app/models/user.rb`  
**Table**: `users`  
**Primary Key**: `id` (bigint, auto-increment)

## Database Schema

```sql
CREATE TABLE users (
  id           bigint PRIMARY KEY,
  username     string NOT NULL,
  password_digest string NOT NULL,  
  created_at   timestamp NOT NULL,
  updated_at   timestamp NOT NULL
);

CREATE UNIQUE INDEX index_users_on_username ON users (username);
```

## Attributes

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | `bigint` | Primary Key, Auto-increment | Unique user identifier |
| `username` | `string` | NOT NULL, Unique | User's login identifier |
| `password_digest` | `string` | NOT NULL | bcrypt-hashed password |
| `created_at` | `timestamp` | NOT NULL | Record creation time |
| `updated_at` | `timestamp` | NOT NULL | Last modification time |

## Associations

```ruby
class User < ApplicationRecord
  # One-to-many associations with cascading delete
  has_many :road_trips, dependent: :destroy
  has_many :routes, dependent: :destroy
end
```

### Association Details

#### `has_many :road_trips`
- **Type**: One-to-many relationship
- **Foreign Key**: `user_id` in `road_trips` table
- **Dependent**: `:destroy` - Deletes all user's road trips when user is deleted
- **Usage**: `user.road_trips` returns all trips owned by the user

#### `has_many :routes`
- **Type**: One-to-many relationship  
- **Foreign Key**: `user_id` in `routes` table
- **Dependent**: `:destroy` - Deletes all user's routes when user is deleted
- **Usage**: `user.routes` returns all routes created by the user

## Authentication

### Password Security

```ruby
class User < ApplicationRecord
  has_secure_password
end
```

The User model uses Rails' `has_secure_password` which provides:

- **bcrypt encryption**: Passwords are hashed using bcrypt with salt
- **Password confirmation**: Automatic validation for password confirmation
- **Authentication method**: `authenticate(password)` method for login
- **Secure defaults**: Follows Rails security best practices

### Password Requirements

```ruby
validates :password, 
  presence: true,
  length: { minimum: 8 },
  format: { 
    with: /\A(?=.*[a-zA-Z])(?=.*\d).*\z/,
    message: "must contain both letters and numbers" 
  }
```

**Password Rules**:
- Minimum 8 characters length
- Must contain at least one letter
- Must contain at least one number
- Special characters are allowed but not required

## Validations

### Username Validation

```ruby
validates :username,
  presence: true,
  length: { minimum: 3 },
  uniqueness: { case_sensitive: false }
```

**Username Rules**:
- Required field (cannot be blank)
- Minimum 3 characters length
- Must be unique across all users (case-insensitive)
- Automatically converted to lowercase before saving

### Data Normalization

```ruby
before_save :downcase_username

private

def downcase_username
  self.username = username.downcase if username.present?
end
```

**Normalization Process**:
- Username is converted to lowercase before database storage
- Ensures consistent username format regardless of user input
- Supports case-insensitive uniqueness validation

## Usage Examples

### User Registration

```ruby
# Create a new user
user = User.create!(
  username: 'john_doe',
  password: 'secure123',
  password_confirmation: 'secure123'
)

# The username will be automatically downcased to 'john_doe'
puts user.username  # => "john_doe"
```

### User Authentication

```ruby
# Find user by username (case-insensitive)
user = User.find_by(username: 'JOHN_DOE')  # Works due to downcasing

# Authenticate user
if user&.authenticate('secure123')
  # Login successful
  session[:user_id] = user.id
else
  # Login failed
  flash[:error] = 'Invalid credentials'
end
```

### Data Access

```ruby
# Get all road trips for a user
user = User.find(1)
trips = user.road_trips.includes(:routes)

# Get total number of routes created by user
route_count = user.routes.count

# Get user's most recent trip
latest_trip = user.road_trips.order(created_at: :desc).first
```

## Security Features

### Password Protection

- **bcrypt hashing**: Industry-standard password hashing
- **Salt generation**: Automatic salt generation for each password
- **Timing attack protection**: Constant-time password comparison
- **Password confirmation**: Built-in confirmation validation

### Input Validation

- **SQL injection prevention**: ActiveRecord parameterized queries
- **XSS prevention**: Automatic output escaping in views
- **Length validation**: Prevents excessively long usernames
- **Format validation**: Ensures password complexity

### Access Control

```ruby
# Controller pattern for user authorization
class ApplicationController < ActionController::Base
  private
  
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  
  def authenticate_user!
    redirect_to login_path unless current_user
  end
end
```

## Performance Considerations

### Database Indexes

```sql
-- Unique index for fast username lookups
CREATE UNIQUE INDEX index_users_on_username ON users (username);

-- Indexes on foreign key columns for efficient joins
CREATE INDEX index_road_trips_on_user_id ON road_trips (user_id);
CREATE INDEX index_routes_on_user_id ON routes (user_id);
```

### Query Optimization

```ruby
# Efficient user data loading with associations
user_with_data = User.includes(:road_trips, :routes).find(id)

# Avoid N+1 queries when displaying user trips
trips_with_routes = user.road_trips.includes(:routes)
```

## Testing

### Model Specs

```ruby
# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }
    
    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_length_of(:username).is_at_least(3) }
    it { is_expected.to validate_uniqueness_of(:username).case_insensitive }
    it { is_expected.to validate_presence_of(:password) }
    it { is_expected.to validate_length_of(:password).is_at_least(8) }
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

  describe 'password validation' do
    it 'requires letters and numbers' do
      user = build(:user, password: '12345678')
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('must contain both letters and numbers')
    end
  end
end
```

### Factory Definition

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    password { 'password123' }
    password_confirmation { 'password123' }
    
    trait :with_trips do
      after(:create) do |user|
        create_list(:road_trip, 3, user: user)
      end
    end
  end
end
```

## Common Patterns

### User Registration Flow

```ruby
class UsersController < ApplicationController
  def create
    @user = User.new(user_params)
    
    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: 'Account created successfully!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :password, :password_confirmation)
  end
end
```

### Session Management

```ruby
class SessionsController < ApplicationController
  def create
    user = User.find_by(username: params[:username])
    
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to root_path, notice: 'Logged in successfully!'
    else
      flash.now[:error] = 'Invalid username or password'
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: 'Logged out successfully!'
  end
end
```

## Future Enhancements

### Planned Features

1. **Email Authentication**: Add email field for password reset
2. **Profile Information**: Extended user profile with preferences
3. **Social Login**: OAuth integration with Google/Facebook
4. **Two-Factor Authentication**: Enhanced security with 2FA
5. **User Roles**: Admin/user role system for management features

### Migration Considerations

```ruby
# Future migration example for email field
class AddEmailToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :email, :string
    add_index :users, :email, unique: true
  end
end
```

The User model provides a secure, scalable foundation for authentication while maintaining simplicity and following Rails conventions.