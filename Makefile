.PHONY: build up down logs bash console reset-db clean test test-fast css-build css-watch lint lint-fix importmap

# Build Docker images
build:
	docker compose build

# Start services
up:
	docker compose up

# Start services in background
upd:
	docker compose up -d

# Stop services
down:
	docker compose down

# View logs
logs:
	docker compose logs -f

# Open bash shell in web container
bash:
	docker compose exec web bash

# Open Rails console
console:
	docker compose exec web bin/rails console

# Run database migrations
migrate:
	docker compose exec web bin/rails db:migrate

# Reset database
reset-db:
	docker compose exec web bin/rails db:drop db:create db:migrate db:seed

# Clean everything (containers, volumes, images)
clean:
	docker compose down -v
	docker rmi roadtrip_planner-web || true

# Run all tests
test:
	docker compose exec web bundle exec rspec

# Run fast tests only (models)
test-fast:
	docker compose exec web bundle exec rspec spec/models/

# Check routes
routes:
	docker compose exec web bin/rails routes

# Build CSS for production
css-build:
	docker compose exec web npm run build-css:production

# Watch CSS changes (for development)
css-watch:
	docker compose exec web npm run build-css:watch

# Run Ruby linter
lint:
	docker compose exec web bundle exec rubocop

# Run Ruby linter with auto-fix
lint-fix:
	docker compose exec web bundle exec rubocop -A

# Show importmap packages
importmap:
	docker compose exec web bin/importmap packages