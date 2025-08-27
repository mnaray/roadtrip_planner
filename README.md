# Roadtrip Planner

This is a Ruby on Rails application to plan your roadtrips. The application uses PostgreSQL as the database and is designed to run in a containerized development environment using Docker Compose.

## Development Setup

### Prerequisites

- Docker and Docker Compose
- Git

### Getting Started

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
   - Start the Rails development server on port 3000

3. **Setup the database:**
   ```bash
   # In a new terminal, run database migrations
   docker compose exec web rails db:create
   docker compose exec web rails db:migrate
   ```

4. **Access the application:**
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
  docker compose exec web rails test
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

#### SSL Certificate Issues

If you encounter SSL certificate verification errors during the Docker build process, this may be due to corporate firewalls or proxy settings. You can resolve this by:

1. **Update the Dockerfile** to disable SSL verification temporarily (development only):
   ```dockerfile
   RUN gem install rails --no-document --source http://rubygems.org/
   ```

2. **Or configure your network** to allow access to `https://rubygems.org/`

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

## Next Steps

This is a basic Rails application setup. You can now:

- Add authentication (devise gem)
- Create models for trips, destinations, routes
- Add a user interface for planning roadtrips
- Integrate with mapping APIs (Google Maps, Mapbox)
- Add features like weather integration, points of interest, etc.
