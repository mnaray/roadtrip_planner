# Roadtrip Planner

This is a Ruby on Rails application to plan your roadtrips. The application uses PostgreSQL as the database and is designed to run in a containerized development environment using Docker Compose.

## Development Setup

### Prerequisites

- Docker and Docker Compose
- Git

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd roadtrip_planner
   ```

2. **Build and start the application:**
   ```bash
   docker compose up --build
   ```

   This will:
   - Build the Rails application container
   - Start a PostgreSQL database container  
   - Automatically install Ruby gems, prepare the database, and start the Rails server

   **Note**: If gem installation fails due to network restrictions (common in corporate environments), see the troubleshooting section below.

3. **Access the application:**
   - Open your browser and navigate to `http://localhost:3000`
   - You should see a welcome message from the Rails application

### Development Workflow

The development environment is configured to support live code changes without rebuilding the Docker image:

- **Code Changes**: Any changes to the application code will be automatically reflected when you refresh the browser (thanks to Rails' auto-reloading in development)
- **Gemfile Changes**: If you modify the `Gemfile`, you'll need to rebuild the container:
  ```bash
  docker compose down
  docker compose up --build
  ```
- **Database Changes**: Run migrations after creating new migration files:
  ```bash
  docker compose exec web rails db:migrate
  ```

### Useful Commands

- **Start the application:**
  ```bash
  docker compose up
  ```

- **Stop the application:**
  ```bash
  docker compose down
  ```

- **View logs:**
  ```bash
  docker compose logs -f web
  ```

- **Access Rails console:**
  ```bash
  docker compose exec web rails console
  ```

- **Run tests:**
  ```bash
  docker compose exec web rspec
  ```

- **Generate new Rails components:**
  ```bash
  # Generate a new controller
  docker compose exec web rails generate controller Welcome index

  # Generate a new model
  docker compose exec web rails generate model User name:string email:string

  # Generate a new migration
  docker compose exec web rails generate migration AddAgeToUsers age:integer
  ```

### Project Structure

```
roadtrip_planner/
├── app/                    # Rails application code
│   ├── controllers/        # Controllers
│   ├── models/            # Models
│   ├── views/             # Views
│   └── ...
├── config/                # Configuration files
│   ├── database.yml       # Database configuration
│   ├── routes.rb          # Application routes
│   └── ...
├── db/                    # Database files
│   └── migrate/           # Database migrations
├── docker-compose.yml     # Docker Compose configuration
├── Dockerfile            # Docker image definition
├── Gemfile               # Ruby gem dependencies
└── README.md             # This file
```

### Environment Variables

The following environment variables are configured in `docker-compose.yml`:

- `DATABASE_URL`: PostgreSQL connection string
- `RAILS_ENV`: Set to 'development'

### Database Configuration

The application is configured to use PostgreSQL with the following default settings:

- **Host**: `db` (Docker service name)
- **Username**: `roadtrip_planner`
- **Password**: `password`
- **Database**: `roadtrip_planner_development`
- **Port**: `5432`

### Troubleshooting

#### PostgreSQL Version Compatibility Issues

If you see an error like "database files are incompatible with server" or "The data directory was initialized by PostgreSQL version 16, which is not compatible with this version 15", this means you have an existing PostgreSQL data volume from a different version:

**Solution: Clean up the old data volume**
```bash
# Stop all containers
docker compose down

# Remove the old PostgreSQL data volume
docker volume rm roadtrip_planner_postgres_data

# Start fresh
docker compose up --build
```

This will create a new PostgreSQL 16 database from scratch.

#### Network Restrictions / Gem Installation Issues

If you see errors like "Access token could not be authenticated for http://rubygems.org/" or "Authentication is required for http://rubygems.org/", this indicates network restrictions preventing access to rubygems.org (common in corporate environments or CI/CD systems).

**The container will show these symptoms:**
- Gems fail to install during startup
- Rails shows "rails new" usage instead of starting the server
- Container keeps restarting

**Solution Options:**

**Option 1: Use the manual setup workflow**
```bash
# Stop any running containers
docker compose down

# Start only the database
docker compose up -d db

# Run an interactive session in the web container
docker compose run --rm web bash

# Inside the container, try manual setup:
bundle config set --global silence_root_warning true
bundle install

# If bundle install works, continue with Rails setup:
bundle exec rails db:prepare
bundle exec rails server -b 0.0.0.0
```

**Option 2: Pre-build with gems (if you have external access)**
If you have access to rubygems.org from another environment:
1. Generate a complete `Gemfile.lock` with access to rubygems.org
2. Copy it to your restricted environment
3. Use `bundle install --deployment` which uses the lockfile

**Option 3: Use a gem cache or mirror**
If your organization provides a gem cache or mirror:
```ruby
# Modify the first line of Gemfile
source "https://your-internal-gem-mirror.com"
```

**Option 4: Wait and retry**
Network restrictions are sometimes temporary. The container is configured with restart policies, so it will keep trying to start. You can monitor progress with:
```bash
docker compose logs -f web
```

#### Port Conflicts

If port 3000 or 5432 are already in use on your system:

1. **Stop conflicting services** or
2. **Modify docker-compose.yml** to use different ports:
   ```yaml
   services:
     web:
       ports:
         - "3001:3000"  # Use port 3001 instead
     db:
       ports:
         - "5433:5432"  # Use port 5433 instead
   ```

#### Container Issues

If containers fail to start:

1. **Clean up Docker resources:**
   ```bash
   docker compose down -v
   docker system prune -f
   ```

2. **Rebuild from scratch:**
   ```bash
   docker compose up --build --force-recreate
   ```

## Contributing

This application is set up for development. To add new features:

1. Create new controllers, models, or views using Rails generators
2. Write tests for your new functionality
3. Run the test suite to ensure everything works
4. Update this README if you add new setup requirements

## Summary

This repository contains a complete Ruby on Rails application setup for roadtrip planning with:

- **Rails 8.0** application framework
- **PostgreSQL** database configuration
- **Docker & Docker Compose** development environment
- **Live code reloading** support
- **RSpec** testing framework
- **Comprehensive documentation** and troubleshooting guides

The application is ready for development and can be extended with roadtrip planning features such as:
- User authentication and profiles
- Trip creation and management
- Route planning and optimization
- Points of interest integration
- Weather and traffic data
- Collaborative trip planning

## Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   Rails App     │    │   PostgreSQL    │
│   (Port 3000)   │────│   (Port 5432)   │
│                 │    │                 │
│ • Controllers   │    │ • Development   │
│ • Models        │    │ • Test          │
│ • Views         │    │ • Production    │
│ • API Endpoints │    │   Databases     │
└─────────────────┘    └─────────────────┘
```

The development environment supports:
- **Hot reloading**: Code changes are reflected immediately
- **Volume mounting**: No need to rebuild containers for code changes
- **Database persistence**: Data survives container restarts
- **Testing**: Integrated RSpec test suite
- **Debugging**: Rails console and logging support
