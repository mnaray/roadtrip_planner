---
id: deployment
title: Production Deployment Guide
sidebar_label: Deployment
---

# Production Deployment Guide

This guide covers deploying the Roadtrip Planner application to production environments using Docker containers.

## Prerequisites

Before deploying to production, ensure your server meets these requirements:

- **Docker Engine** and **Docker Compose** installed
- **Minimum 2GB RAM** and **10GB disk space** available
- **Port 3000** available (or configure alternative port)
- **Internet connectivity** to pull Docker images from Docker Hub

## Deployment Strategies

We provide three different deployment approaches depending on your needs:

### 1. Building a New Image Locally

:::info
Building locally is only required if you want to use the development version in production or need to customize the Docker image.
:::

#### Step 1: Build the Docker Image

```bash
docker build -t mnaray/roadtrip-planner:v1.0.0 .
```

Replace `v1.0.0` with your desired version number.

#### Step 2: Push to Docker Hub

```bash
# Login to Docker Hub
docker login

# Push the image
docker push mnaray/roadtrip-planner:v1.0.0
```

:::tip
Replace `mnaray` with your own Docker Hub username if you're forking the project.
:::

### 2. Deploying an Existing Image

This is the recommended approach for most production deployments.

#### Step 1: Get Production Configuration

Download the production Docker Compose file:

```bash
curl -o docker-compose.production.yml \
  https://raw.githubusercontent.com/mnaray/roadtrip_planner/main/docker-compose.production.yml
```

#### Step 2: Configure Credentials

Edit the downloaded `docker-compose.production.yml` file and replace these placeholders with your actual values:

- `REPLACE_WITH_YOUR_SECURE_DATABASE_PASSWORD` → Your secure database password
- `REPLACE_WITH_YOUR_SECRET_KEY_BASE` → Generated secret key (see [Generating Secret Keys](#generating-secret-keys))
- `REPLACE_WITH_YOUR_RAILS_MASTER_KEY` → Your Rails master key from `config/master.key`

:::warning Security
- Use strong, unique passwords for the database
- Generate new secret keys for production
- Never commit sensitive credentials to version control
:::

#### Step 3: Deploy the Application

```bash
# Start all services
docker compose -f docker-compose.production.yml up -d

# Verify deployment
docker compose -f docker-compose.production.yml ps

# View application logs
docker compose -f docker-compose.production.yml logs -f web
```

#### Step 4: Access Your Application

Navigate to `http://your-server-ip:3000` in your web browser.

### 3. Updating Production Deployments

For production environments, updating to newer versions is straightforward with Docker Compose.

#### Step 1: Update the Image Version

Edit your `docker-compose.production.yml` file and change the image tag:

```yaml
web:
  image: mnaray/roadtrip-planner:v1.2.3  # Update to desired version
```

#### Step 2: Apply the Update

```bash
# Pull the new image
docker compose -f docker-compose.production.yml pull web

# Gracefully restart the web service
docker compose -f docker-compose.production.yml up -d web

# Run database migrations if needed
docker compose -f docker-compose.production.yml exec web rails db:migrate
```

:::info Update Process
- Database data persists during the update
- Minimal downtime during service restart
- Automatic migration execution ensures schema compatibility
- Rollback possible by reverting to previous image version
:::

Replace `v1.2.3` with your desired version tag from Docker Hub.

## Configuration

### Generating Secret Keys

#### SECRET_KEY_BASE
```bash
docker run --rm mnaray/roadtrip-planner:v1.0.0 rails secret
```

#### RAILS_MASTER_KEY
The master key is found in your Rails application's `config/master.key` file.

## Production Docker Compose Configuration

The production compose file includes several optimizations:

### Database Optimizations
- **PostgreSQL 17** with performance tuning
- **Persistent data storage** with named volumes
- **Health checks** for reliability
- **Connection limits** and memory settings

### Web Service Features
- **Health checks** via `/up` endpoint
- **Restart policies** for fault tolerance
- **Environment isolation** with dedicated network
- **Static file serving** without external web server

### Security Features
- **No development volumes** mounted
- **Isolated network** for service communication
- **Environment variable** injection only
- **Read-only containers** where possible

## Monitoring and Maintenance

### Viewing Logs

```bash
# View all service logs
docker compose -f docker-compose.production.yml logs -f

# View only web application logs
docker compose -f docker-compose.production.yml logs -f web

# View only database logs  
docker compose -f docker-compose.production.yml logs -f db
```

### Health Monitoring

```bash
# Check service status
docker compose -f docker-compose.production.yml ps

# Test application health endpoint
curl http://your-server:3000/up

# Monitor resource usage
docker stats
```

### Database Operations

#### Creating Backups

```bash
# Create a database backup
docker compose -f docker-compose.production.yml exec db pg_dump \
  -U roadtrip_planner roadtrip_planner_production > backup_$(date +%Y%m%d).sql
```

#### Running Migrations

```bash
# Run database migrations
docker compose -f docker-compose.production.yml exec web rails db:migrate

# Check migration status
docker compose -f docker-compose.production.yml exec web rails db:version
```

### Service Management

```bash
# Restart all services
docker compose -f docker-compose.production.yml restart

# Restart only the web service
docker compose -f docker-compose.production.yml restart web

# Stop all services
docker compose -f docker-compose.production.yml down

# Stop and remove all data (WARNING: DATA LOSS)
docker compose -f docker-compose.production.yml down -v
```

## Troubleshooting

### Common Issues

#### Port Already in Use

If port 3000 is occupied:

```bash
# Check what's using the port
sudo netstat -tulpn | grep :3000

# Or modify the port in your .env file
echo "PORT=3001" >> .env
```

#### Database Connection Issues

```bash
# Check database container status
docker compose -f docker-compose.production.yml ps db

# View database logs
docker compose -f docker-compose.production.yml logs db

# Test database connectivity
docker compose -f docker-compose.production.yml exec web rails db:version
```

#### Service Won't Start

```bash
# Check service health
docker compose -f docker-compose.production.yml ps

# View detailed logs
docker compose -f docker-compose.production.yml logs --tail=100

# Restart problematic service
docker compose -f docker-compose.production.yml restart web
```

### Performance Issues

#### Memory Usage

```bash
# Monitor memory usage
docker stats --no-stream

# Check database performance
docker compose -f docker-compose.production.yml exec db \
  psql -U roadtrip_planner -d roadtrip_planner_production \
  -c "SELECT * FROM pg_stat_activity;"
```

#### Disk Space

```bash
# Check Docker disk usage
docker system df

# Clean up unused resources
docker system prune -a

# Check database size
docker compose -f docker-compose.production.yml exec db \
  psql -U roadtrip_planner -d roadtrip_planner_production \
  -c "SELECT pg_size_pretty(pg_database_size('roadtrip_planner_production'));"
```

## Security Considerations

### Environment Security

- **Never commit** `.env` files to version control
- **Rotate secrets** regularly, especially in case of security incidents
- **Use strong passwords** for database credentials
- **Limit network access** to only necessary ports

### Container Security

- **Regular updates**: Keep Docker images updated
- **Minimal privileges**: Services run as non-root users
- **Isolated networking**: Services communicate via Docker networks
- **Read-only filesystems**: Where possible, containers use read-only filesystems

### Database Security

- **Strong authentication**: Use complex database passwords
- **Network isolation**: Database not exposed to external networks
- **Regular backups**: Implement automated backup strategies
- **Access logging**: Monitor database access patterns

## Production Checklist

Before going live, ensure:

- [ ] All environment variables are configured
- [ ] Database passwords are secure and unique
- [ ] SSL/TLS certificates are configured (if using HTTPS)
- [ ] Backup strategy is implemented
- [ ] Monitoring and logging are set up
- [ ] Health checks are functioning
- [ ] Resource limits are appropriate
- [ ] Security patches are applied
- [ ] Documentation is updated for your team

:::tip Next Steps
After successful deployment, consider setting up:
- **Reverse proxy** (nginx/Apache) for SSL termination
- **Monitoring tools** (Prometheus/Grafana) for observability
- **Automated backups** with off-site storage
- **CI/CD pipelines** for automated deployments
:::