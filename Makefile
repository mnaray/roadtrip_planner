.PHONY: build up down logs bash console reset-db clean css-build css-watch lint lint-fix

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

# Run tests
test:
	docker compose exec web bin/rails test

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