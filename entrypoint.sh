#!/bin/bash
set -e

echo "=== Starting Roadtrip Planner application ==="
echo "Rails environment: $RAILS_ENV"
echo "Database URL: $DATABASE_URL"

echo "=== Step 1: Checking gem dependencies ==="
if bundle check > /dev/null 2>&1; then
  echo "✓ All gems are already installed"
else
  echo "Installing missing gems..."
  bundle config set --local retry 3
  bundle config set --local timeout 30
  
  # Install gems with better error handling
  if ! bundle install 2>&1; then
    echo "❌ Failed to install gems - check network connectivity"
    echo "You can run manual setup with: docker compose run --rm web bash"
    exit 1
  fi
  echo "✓ Gems installed successfully"
fi

# Clean up gem warnings by running bundle clean
echo "=== Step 1.5: Cleaning up gem installation ==="
bundle clean --force 2>/dev/null || echo "Note: Bundle clean completed with warnings (this is normal)"

echo "=== Step 2: Removing stale PID files ==="
rm -f tmp/pids/server.pid
echo "✓ PID files cleaned"

echo "=== Step 3: Waiting for database ==="
max_attempts=30
attempt=0
until pg_isready -h db -p 5432 -U roadtrip_planner > /dev/null 2>&1; do
  attempt=$((attempt + 1))
  if [ $attempt -gt $max_attempts ]; then
    echo "❌ Database connection timeout after ${max_attempts} attempts"
    echo "Check if PostgreSQL container is running: docker compose ps"
    exit 3
  fi
  echo "Waiting for PostgreSQL to be ready... (attempt $attempt/$max_attempts)"
  sleep 2
done
echo "✓ Database is ready"

echo "=== Step 4: Preparing database ==="
if ! bundle exec rails db:prepare 2>&1; then
  echo "❌ Database preparation failed"
  echo "This might be due to:"
  echo "  - Database connection issues"
  echo "  - Permission problems"
  echo "  - Database schema conflicts"
  echo ""
  echo "Database connection details:"
  echo "  Host: db"
  echo "  Port: 5432" 
  echo "  User: roadtrip_planner"
  echo "  Database: roadtrip_planner_development"
  echo ""
  echo "Try running: docker compose run --rm web bundle exec rails db:reset"
  exit 4
fi
echo "✓ Database prepared successfully"

echo "=== Step 5: Starting Rails server ==="
echo "Server will be available at http://localhost:3000"
echo "Starting server..."

# Start the Rails server with explicit error handling
if ! bundle exec rails server -b 0.0.0.0; then
  echo "❌ Rails server failed to start"
  echo "This might be due to:"
  echo "  - Port 3000 already in use"
  echo "  - Application configuration errors"
  echo "  - Missing gems or dependencies"
  echo ""
  echo "For debugging, run: docker compose run --rm web bash"
  echo "Then manually run: bundle exec rails server -b 0.0.0.0"
  exit 5
fi