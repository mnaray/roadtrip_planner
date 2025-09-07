.PHONY: build up down logs bash console reset-db clean test rspec rspec-fast rspec-requests rspec-requests-safe rspec-models rspec-helpers rspec-failures rspec-debug rspec-all css-build css-watch lint lint-fix importmap

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

# Run optimized tests (models + helpers - fast and reliable)
# This matches what CI runs: only the stable, fast-running specs
test:
	docker compose exec web bundle exec rspec spec/models/ spec/helpers/

# Run RSpec tests (same as test for consistency)
rspec:
	docker compose exec web bundle exec rspec spec/models/ spec/helpers/

# Run fast tests with profiling for performance monitoring
rspec-fast:
	docker compose exec web bundle exec rspec spec/models/ spec/helpers/ --profile 10

# Run only request specs (may be slow - use specific files)
rspec-requests:
	@echo "⚠️  Request specs may hang. Try: make rspec-requests-safe"
	docker compose exec web bundle exec rspec spec/requests

# Run safe request specs (working ones only)
rspec-requests-safe:
	docker compose exec web bundle exec rspec spec/requests/user_login_spec.rb spec/requests/user_registration_spec.rb spec/requests/password_reset_spec.rb

# Run only model specs
rspec-models:
	docker compose exec web bundle exec rspec spec/models

# Run only helper specs
rspec-helpers:
	docker compose exec web bundle exec rspec spec/helpers

# Re-run only failed tests
rspec-failures:
	docker compose exec web bundle exec rspec --only-failures

# Run tests with verbose output for debugging
rspec-debug:
	docker compose exec web bundle exec rspec spec/models/ spec/helpers/ --format documentation

# Run ALL tests (including potentially slow service/request specs)
rspec-all:
	@echo "⚠️  Running full test suite including service specs (may be slow)"
	docker compose exec web bundle exec rspec

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