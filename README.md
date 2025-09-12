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

## Deployment

This section covers deploying the Roadtrip Planner application to production environments.

### Prerequisites for Production Deployment

- Docker Engine and Docker Compose installed on your production server
- At least 2GB RAM and 10GB disk space available
- Port 3000 available (or configure a different port)
- Internet connectivity to pull Docker images

### Building a New Image Locally

**Note:** Building locally is only required if you want to use the development version in production or need to customize the image.

1. **Build the Docker image:**
   ```bash
   docker build -t mnaray/roadtrip-planner:v1.0.0 .
   ```

2. **Push the image to Docker Hub:** (Replace with your Docker Hub username)
   ```bash
   # Login to Docker Hub
   docker login
   
   # Push the image
   docker push mnaray/roadtrip-planner:v1.0.0
   ```

### Deploying an Existing Image to Production

1. **Download the production Docker Compose file:**
   ```bash
   # Download the production compose file
   curl -o docker-compose.production.yml \
     https://raw.githubusercontent.com/mnaray/roadtrip_planner/main/docker-compose.production.yml
   ```

2. **Configure your credentials:**
   Edit the downloaded `docker-compose.production.yml` file and replace the following placeholders:
   - Replace `REPLACE_WITH_YOUR_SECURE_DATABASE_PASSWORD` with your secure database password
   - Replace `REPLACE_WITH_YOUR_SECRET_KEY_BASE` with your secret key base (generate using the command below)
   - Replace `REPLACE_WITH_YOUR_RAILS_MASTER_KEY` with your Rails master key from `config/master.key`

3. **Start the application:**
   ```bash
   # Start all services
   docker compose -f docker-compose.production.yml up -d
   
   # Check service status
   docker compose -f docker-compose.production.yml ps
   
   # View logs
   docker compose -f docker-compose.production.yml logs -f
   ```

4. **Open the application:**
   Navigate to `http://your-server-ip:3000` in your web browser.

### Deploying Updates Without Data Loss

To update your production deployment to a newer version:

1. **Update the Docker image version:**
   Edit your `docker-compose.production.yml` file and change the image tag:
   ```yaml
   web:
     image: mnaray/roadtrip-planner:v1.2.3  # Update to desired version
   ```

2. **Apply the update:**
   ```bash
   # Pull the new image
   docker compose -f docker-compose.production.yml pull web
   
   # Gracefully restart the web service
   docker compose -f docker-compose.production.yml up -d web
   
   # Run database migrations if needed
   docker compose -f docker-compose.production.yml exec web rails db:migrate
   ```

**Note:** This approach ensures database persistence while updating the application. Replace `v1.2.3` with your desired version.

### Generating Secret Keys

When configuring your production deployment, you'll need to generate a secret key base:

```bash
# Generate SECRET_KEY_BASE
docker run --rm mnaray/roadtrip-planner:v1.0.0 rails secret
```

The `RAILS_MASTER_KEY` is found in your Rails application's `config/master.key` file.

### Monitoring and Maintenance

#### View Application Logs
```bash
docker compose -f docker-compose.production.yml logs -f web
```

#### Database Backup
```bash
# Create database backup
docker compose -f docker-compose.production.yml exec db pg_dump \
  -U roadtrip_planner roadtrip_planner_production > backup.sql
```

#### Restart Services
```bash
# Restart all services
docker compose -f docker-compose.production.yml restart

# Restart only web service
docker compose -f docker-compose.production.yml restart web
```

#### Stop Services
```bash
docker compose -f docker-compose.production.yml down
```

### Troubleshooting Production Issues

#### Check Service Health
```bash
docker compose -f docker-compose.production.yml ps
docker compose -f docker-compose.production.yml logs web
```

#### Database Connection Issues
```bash
# Check database logs
docker compose -f docker-compose.production.yml logs db

# Test database connection
docker compose -f docker-compose.production.yml exec web rails db:version
```

#### Performance Monitoring
```bash
# Monitor resource usage
docker stats

# Check application health endpoint
curl http://your-server:3000/up
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