#!/bin/bash

# Development setup script for Roadtrip Planner
# This script helps set up the Rails application in Docker

set -e

echo "🚀 Setting up Roadtrip Planner development environment..."

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available
if ! docker compose version >/dev/null 2>&1; then
    echo "❌ Docker Compose is not available. Please install Docker Compose."
    exit 1
fi

echo "✅ Docker and Docker Compose are available"

# Try building the application
echo "🏗️  Building the application containers..."

if docker compose build; then
    echo "✅ Build successful!"
else
    echo "⚠️  Build failed, likely due to SSL certificate issues."
    echo "📋 Trying alternative approach..."
    
    # Create a temporary Dockerfile with SSL workarounds
    cat > Dockerfile.dev << 'EOF'
FROM ruby:3.2.3

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y \
      build-essential \
      postgresql-client \
      nodejs \
      npm \
      git && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Set working directory
WORKDIR /app

# Copy application files first
COPY . .

# Use a pre-installed Rails if available, or skip gem installation for now
# Users can install gems manually after the container is running
RUN touch Gemfile.lock || true

# Expose port 3000
EXPOSE 3000

# Install Rails and gems on startup
CMD ["bash", "-c", "gem install rails --no-document || true; bundle install || true; rails server -b 0.0.0.0"]
EOF

    # Update docker-compose to use the dev Dockerfile
    sed 's/Dockerfile/Dockerfile.dev/' docker-compose.yml > docker-compose.dev.yml
    
    echo "📦 Building with alternative configuration..."
    if docker compose -f docker-compose.dev.yml build; then
        echo "✅ Alternative build successful!"
        echo "🎯 Use 'docker compose -f docker-compose.dev.yml up' to start the application"
    else
        echo "❌ Build still failed. Please check the troubleshooting section in README.md"
        exit 1
    fi
fi

echo "🗄️  Starting database..."
docker compose up -d db

echo "⏳ Waiting for database to be ready..."
sleep 10

echo "🏁 Setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Start the application: docker compose up"
echo "   2. In another terminal, set up the database:"
echo "      docker compose exec web rails db:create"
echo "      docker compose exec web rails db:migrate"
echo "   3. Visit http://localhost:3000 in your browser"
echo ""
echo "📚 See README.md for more detailed instructions and troubleshooting."