# Roadtrip Planner

A Rails 8 application for planning and managing road trips, built with modern web technologies and containerized for easy development.

## Technology Stack

- **Rails**: 8.0.2.1
- **Ruby**: 3.4.x
- **Database**: PostgreSQL 17
- **Frontend**: 
  - Phlex components for view layer
  - Tailwind CSS v4 for styling
  - Importmaps for JavaScript (no Node.js build step required)
  - Stimulus.js for JavaScript behavior
- **Authentication**: Custom implementation using bcrypt
- **Testing**: RSpec with FactoryBot
- **Containerization**: Docker & Docker Compose

## Features

### ✅ Implemented Features
- **User Authentication**: Secure registration, login, and logout system
- **Road Trip Management**: Create, edit, view, and delete road trip plans
- **Route Planning**: Add individual route segments to road trips with starting location, destination, and timing
- **Component-Based Architecture**: Modern UI built with Phlex components
- **Responsive Design**: Mobile-friendly interface with Tailwind CSS v4
- **Real-time Feedback**: Interactive forms with validation and user feedback
- **Dockerized Environment**: Complete containerized development setup
- **PostgreSQL Database**: Robust data storage with proper relationships

### 🚧 Planned Features  
- Route mapping integration with interactive maps
- GPS/GPX export functionality for routes
- Accommodation and activity planning
- Expense tracking for trips
- Trip sharing and collaboration
- Photo galleries for trip memories
- Offline mode support

## Prerequisites

- Docker Desktop or Docker Engine with Docker Compose
- Git

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/mnaray/roadtrip_planner.git
cd roadtrip_planner
```

### 2. Set up environment variables

Create a `.env` file in the project root (if not already present):

```bash
POSTGRES_DB=roadtrip_planner_development
POSTGRES_USER=roadtrip_planner
POSTGRES_PASSWORD=your_secure_password
DATABASE_HOST=db
```

### 3. Build and run with Docker

```bash
# Build the Docker images
docker compose build

# Start the application
docker compose up

# Or run in detached mode
docker compose up -d
```

The first run will automatically:
- Install Ruby gems
- Install Node packages
- Create and migrate the database
- Start the Rails server

### 4. Access the application

Open your browser and navigate to: `http://localhost:3000`

## Development

### Running commands in the container

```bash
# Access the Rails console
docker compose exec web rails console

# Run database migrations
docker compose exec web rails db:migrate

# Run tests
docker compose exec web rspec

# Access bash shell
docker compose exec web bash
```

### Using the Makefile (optional)

A Makefile is provided for common tasks:

```bash
make build    # Build Docker images
make up       # Start services
make down     # Stop services
make logs     # View logs
make bash     # Access container shell
make reset-db # Reset database
```

### Live Reloading

The application supports live reloading:
- Rails code changes are automatically reflected
- CSS changes rebuild automatically in development
- JavaScript changes are loaded via Importmaps

### Documentation

The project includes comprehensive documentation built with Docusaurus:

```bash
# View documentation locally
cd docs
npm install
npm run start
# Open http://localhost:3001 to view documentation
```

The documentation covers:
- Complete setup and development guide
- Architecture and design patterns
- API reference and component documentation
- Testing and deployment procedures

## Project Structure

```
roadtrip_planner/
├── app/
│   ├── components/     # Phlex view components (HomePage, Navigation, Forms)
│   ├── controllers/    # Rails controllers (Users, RoadTrips, Routes)
│   ├── models/         # ActiveRecord models (User, RoadTrip, Route)
│   └── javascript/     # Stimulus controllers and importmaps
├── config/             # Rails configuration and routes
├── db/                 # Database migrations and schema
├── spec/               # RSpec tests with request specs and factories
├── docs/               # Docusaurus documentation site
├── Dockerfile          # Container definition
├── docker-compose.yml  # Multi-container orchestration
├── tailwind.config.js  # Tailwind CSS v4 configuration
└── CLAUDE.md           # AI assistant project instructions
```

## Testing

The application uses RSpec for testing:

```bash
# Run all tests
docker compose exec web rspec

# Run specific test file
docker compose exec web rspec spec/requests/user_registration_spec.rb

# Run with coverage
docker compose exec web rspec --format documentation
```

## Database Management

```bash
# Create database (usually automatic)
docker compose exec web rails db:create

# Run migrations
docker compose exec web rails db:migrate

# Seed database
docker compose exec web rails db:seed

# Reset database
docker compose exec web rails db:reset
```

## Troubleshooting

### Port already in use
If port 3000 is already in use:
```bash
# Stop the running container
docker compose down

# Or change the port in docker-compose.yml
ports:
  - "3001:3000"  # Use port 3001 instead
```

### Database connection issues
```bash
# Check database service status
docker compose ps

# View database logs
docker compose logs db

# Rebuild database
docker compose exec web rails db:drop db:create db:migrate
```

### Clear Docker cache
```bash
# Stop all services
docker compose down

# Remove volumes (WARNING: deletes data)
docker compose down -v

# Rebuild from scratch
docker compose build --no-cache
docker compose up
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with Rails 8 and modern web standards
- Containerized for consistent development environments
- Component-based architecture for maintainable code