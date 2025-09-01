# Development Environment Setup

This guide will help you set up a local development environment for Roadtrip Planner.

## Prerequisites

Before you begin, ensure you have the following installed:

### Required Software

1. **Git**: Version control system
   ```bash
   # Check if installed
   git --version
   ```

2. **Docker Desktop** (recommended) or **Docker Engine** with **Docker Compose**
   - Docker Desktop includes Docker Compose
   - Minimum version: Docker 20.10+ and Docker Compose v2+
   ```bash
   # Check Docker installation
   docker --version
   docker compose version
   ```

### System Requirements

- **Operating System**: Linux, macOS, or Windows with WSL2
- **Memory**: 4GB RAM minimum (8GB recommended)
- **Storage**: 2GB free space for containers and dependencies
- **Network**: Internet connection for downloading dependencies

## Quick Setup

### 1. Clone the Repository

```bash
git clone https://github.com/mnaray/roadtrip_planner.git
cd roadtrip_planner
```

### 2. Environment Configuration

Create a `.env` file in the project root:

```bash
# Copy from the example or create manually
cp .env.example .env

# Or create the file with required variables
cat > .env << EOF
POSTGRES_DB=roadtrip_planner_development
POSTGRES_USER=roadtrip_planner
POSTGRES_PASSWORD=your_secure_password
DATABASE_HOST=db
EOF
```

### 3. Build and Start Services

```bash
# Build Docker images
docker compose build

# Start all services
docker compose up

# Or start in detached mode
docker compose up -d
```

The first run will automatically:
- Install Ruby gems
- Install Node.js packages  
- Create and migrate the database
- Start the Rails server

### 4. Access the Application

Open your browser and navigate to: **http://localhost:3000**

## Detailed Setup Guide

### Docker Configuration

The application uses Docker Compose with the following services:

```yaml
# docker-compose.yml structure
services:
  web:     # Rails application (port 3000)
  db:      # PostgreSQL database (port 5432)
```

#### Service Details

**Web Service:**
- Based on Ruby 3.4-slim image
- Includes Node.js 20.x for frontend tooling
- Runs as non-root user for security
- Volume mounts for live code reloading

**Database Service:**
- PostgreSQL 17 official image
- Persistent data volume
- Configured with environment variables

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_DB` | Database name | `roadtrip_planner_development` |
| `POSTGRES_USER` | Database user | `roadtrip_planner` |
| `POSTGRES_PASSWORD` | Database password | *(required)* |
| `DATABASE_HOST` | Database host | `db` |
| `RAILS_ENV` | Rails environment | `development` |

### Directory Structure

```
roadtrip_planner/
├── app/                 # Application code
│   ├── components/      # Phlex view components
│   ├── controllers/     # Rails controllers
│   ├── models/         # ActiveRecord models
│   ├── services/       # Business logic services
│   └── javascript/     # Stimulus controllers
├── config/             # Rails configuration
├── db/                 # Database migrations and schema
├── spec/               # RSpec tests
├── docs/               # This documentation
├── Dockerfile          # Container definition
├── docker-compose.yml  # Multi-container orchestration
└── .env               # Environment variables (create this)
```

## Common Development Tasks

### Database Operations

```bash
# Create and migrate database
docker compose exec web rails db:create db:migrate

# Reset database
docker compose exec web rails db:reset

# Run migrations
docker compose exec web rails db:migrate

# Rollback migration
docker compose exec web rails db:rollback

# Seed database
docker compose exec web rails db:seed
```

### Running Tests

```bash
# Run all tests
docker compose exec web rspec

# Run specific test file
docker compose exec web rspec spec/requests/user_registration_spec.rb

# Run tests with specific format
docker compose exec web rspec --format documentation

# Run specific test line
docker compose exec web rspec spec/models/user_spec.rb:10
```

### Code Quality Checks

```bash
# Run RuboCop linting
docker compose exec web rubocop

# Auto-fix RuboCop issues
docker compose exec web rubocop -a

# Run security audit
docker compose exec web brakeman

# Run JavaScript import audit
docker compose exec web bin/importmap audit
```

### CSS Development

```bash
# Build CSS (development mode with watching)
docker compose exec web npm run build-css

# Build CSS for production
docker compose exec web npm run build-css:production
```

### Rails Console

```bash
# Open Rails console
docker compose exec web rails console

# Or use the shorter alias
docker compose exec web rails c
```

### Log Monitoring

```bash
# View logs for all services
docker compose logs

# Follow logs in real-time
docker compose logs -f

# View logs for specific service
docker compose logs web
docker compose logs db
```

## Troubleshooting

### Common Issues

#### Port Already in Use
```bash
# Check what's using port 3000
lsof -i :3000

# Stop existing containers
docker compose down
```

#### Database Connection Issues
```bash
# Check database service status
docker compose ps

# View database logs
docker compose logs db

# Reset database service
docker compose down
docker compose up db
```

#### Permission Issues
```bash
# Fix file permissions (Linux/macOS)
sudo chown -R $USER:$USER .

# On Windows WSL2, ensure files are in Linux filesystem
```

#### Container Build Issues
```bash
# Clean build (removes cache)
docker compose build --no-cache

# Remove all containers and volumes
docker compose down -v
docker system prune -a
```

### Performance Optimization

#### Volume Mounting Performance

For better performance on macOS/Windows:

```yaml
# Use cached volumes in docker-compose.yml
volumes:
  - .:/app:cached
  - gem_cache:/usr/local/bundle:delegated
  - node_modules:/app/node_modules:delegated
```

#### Memory Settings

Increase Docker Desktop memory allocation:
- macOS/Windows: Docker Desktop → Settings → Resources → Advanced
- Recommended: 4-8GB RAM

## Development Workflow

### Daily Development

1. **Start Development Environment**
   ```bash
   docker compose up -d
   ```

2. **Make Changes**
   - Code changes are automatically reloaded
   - CSS changes require rebuild: `npm run build-css`

3. **Run Tests**
   ```bash
   docker compose exec web rspec
   ```

4. **Check Code Quality**
   ```bash
   docker compose exec web rubocop
   ```

5. **Stop Environment**
   ```bash
   docker compose down
   ```

### Branch Workflow

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/new-feature
   ```

2. **Develop and Test**
   ```bash
   # Make changes, run tests
   docker compose exec web rspec
   ```

3. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

4. **Push and Create PR**
   ```bash
   git push origin feature/new-feature
   # Create PR on GitHub
   ```

## IDE Setup

### VS Code (Recommended)

Install these extensions:
- Ruby LSP
- Docker
- Ruby Test Explorer
- Tailwind CSS IntelliSense

### RubyMine

Configure Docker integration:
- File → Settings → Build, Execution, Deployment → Docker
- Set up Remote SDK with Docker Compose

## Next Steps

Once your environment is set up:

1. Explore the [Architecture Overview](./architecture/overview.md)
2. Learn about [Models](./models/overview.md)
3. Understand [Services](./services/overview.md)
4. Review Testing Guidelines (coming soon)

## Getting Help

If you encounter issues:

1. Check the [Troubleshooting](#troubleshooting) section
2. Search existing [GitHub Issues](https://github.com/mnaray/roadtrip_planner/issues)
3. Create a new issue with detailed error information
4. Ask for help in the development discussions