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

**Note:** This application is designed to run in Docker containers. All development should be done using Docker to ensure consistency across different development environments.

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

**Important:** All development commands should be run inside the Docker container. Never run Ruby, Rails, or Node.js directly on your host machine for this application.

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

A Makefile is provided for common Docker tasks:

```bash
make build    # Build Docker images
make up       # Start services
make down     # Stop services
make logs     # View logs
make bash     # Access container shell
make reset-db # Reset database
```

**Note:** The Makefile commands are mostly shortcuts for Docker Compose operations. All actual execution happens inside containers.

### Live Reloading

The application supports live reloading within the Docker container:
- Rails code changes are automatically reflected (volume-mounted)
- CSS changes rebuild automatically in development
- JavaScript changes are loaded via Importmaps
- All file watching happens inside the container

### Documentation

The project includes comprehensive documentation built with Docusaurus:

```bash
# View documentation locally (runs in Docker)
docker compose exec web bash -c "cd docs && npm install && npm run start"
# Open http://localhost:3001 to view documentation

# Or run the documentation in a separate container
docker run --rm -it -v $(pwd)/docs:/app -w /app -p 3001:3000 node:20 bash -c "npm install && npm run start"
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

All tests must be run inside the Docker container using RSpec:

```bash
# Run all tests
docker compose exec web rspec

# Run specific test file
docker compose exec web rspec spec/requests/user_registration_spec.rb

# Run with coverage
docker compose exec web rspec --format documentation
```

**Never install RSpec or testing tools on your host machine for this application.** The Docker container includes all necessary testing dependencies.

## Database Management

All database operations are recommended to be run through Docker to ensure environmental consistency. The PostgreSQL database runs in its own container:

```bash
# Create database (usually automatic on first run)
docker compose exec web rails db:create

# Run migrations
docker compose exec web rails db:migrate

# Seed database
docker compose exec web rails db:seed

# Reset database
docker compose exec web rails db:reset

# Access PostgreSQL console
docker compose exec db psql -U roadtrip_planner -d roadtrip_planner_development
```

**Important:** Never install PostgreSQL on your host machine. The database runs entirely in a Docker container.

## Deployment

### Building a new image locally

To build a Docker image for deployment:

```bash
# Build the Docker image with a specific tag
docker build -t roadtrip_planner:latest .

# Or build with a version tag
docker build -t roadtrip_planner:v1.0.0 .

# Push the image to Docker Hub (replace 'yourusername' with your Docker Hub username)
docker tag roadtrip_planner:latest yourusername/roadtrip_planner:latest
docker push yourusername/roadtrip_planner:latest
```

### Deploying an existing image to the production environment

1. **Copy the production Docker Compose file** to your server:
   
   Copy the `docker-compose.production.yml` file to your production server. This file is configured for production use with:
   - Persistent volumes for data preservation
   - Production-optimized PostgreSQL settings
   - Environment-based configuration
   - Health checks and restart policies

2. **Create production environment file**:
   
   Create a `.env.production` file on your server with the following variables:
   ```bash
   # Database Configuration
   POSTGRES_DB=roadtrip_planner_production
   POSTGRES_USER=roadtrip_planner_prod
   POSTGRES_PASSWORD=your_very_secure_password
   
   # Rails Configuration
   SECRET_KEY_BASE=your_secret_key_base_here
   
   # Docker Configuration
   DOCKER_IMAGE=yourusername/roadtrip_planner:latest
   PORT=3000
   ```
   
   Generate a secure secret key base:
   ```bash
   docker run --rm roadtrip_planner:latest bundle exec rails secret
   ```

3. **Start the application**:
   ```bash
   # Pull the latest image
   docker pull yourusername/roadtrip_planner:latest
   
   # Start the containers
   docker compose -f docker-compose.production.yml up -d
   
   # Run database migrations
   docker compose -f docker-compose.production.yml exec web bundle exec rails db:create db:migrate
   ```

4. **Access the application**:
   
   Once the containers are running, access your application at `http://your-server-ip:3000` or configure a reverse proxy (nginx/Apache) to serve it on port 80/443.

### Deploying updates without data loss

A shell script is provided to safely update your deployment without data loss. The script (`scripts/update-deployment.sh`) handles:
- Database migrations
- Asset precompilation
- Zero-downtime container updates
- Automatic rollback on failure

**To make the script executable**:
```bash
chmod +x scripts/update-deployment.sh
```

**Usage**:
```bash
# Update to the latest image
./scripts/update-deployment.sh

# Update to a specific version
./scripts/update-deployment.sh v1.2.0

# The script will prompt you for the compose file location
# Default: ../docker-compose.production.yml
```

The update script performs the following steps:
1. Records the current deployment state for backup
2. Pulls the new Docker image
3. Runs database migrations safely
4. Precompiles assets
5. Updates containers with zero downtime
6. Verifies service health
7. Cleans up old images

**Important Notes**:
- The script preserves all data in Docker volumes
- Database migrations are run before updating containers
- Failed migrations will prevent the update from proceeding
- A backup of the deployment state is saved with timestamp

### Production Best Practices

1. **Use environment variables** for all sensitive configuration
2. **Set up regular backups** of the PostgreSQL data volume
3. **Configure a reverse proxy** (nginx/Apache) for SSL termination
4. **Monitor logs** regularly:
   ```bash
   docker compose -f docker-compose.production.yml logs -f
   ```
5. **Set up health monitoring** for the application endpoints
6. **Use specific version tags** instead of 'latest' for production stability

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