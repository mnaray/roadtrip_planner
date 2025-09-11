# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Roadtrip Planner is a Rails 8 application for planning and managing road trips. The application features user authentication, component-based views with Phlex, and modern styling with Tailwind CSS v4. The entire development environment is containerized with Docker for consistency across development machines.

## Technology Stack

### Core Technologies
- **Rails**: 8.0.2.1 - Modern web application framework
- **Ruby**: 3.4.x - Latest stable Ruby version
- **PostgreSQL**: 17 - Primary database
- **Docker & Docker Compose**: Containerized development environment

### Frontend Stack
- **Phlex**: Component-based Ruby views (replacing traditional ERB templates)
- **Tailwind CSS v4**: Utility-first CSS framework with modern @import syntax
- **Importmaps**: JavaScript without build step
- **Stimulus.js**: Modest JavaScript framework for HTML you already have

### Testing & Quality
- **RSpec**: BDD testing framework with request specs
- **FactoryBot**: Test data generation
- **Rubocop**: Ruby style guide enforcement

## Architecture Decisions

### Component-Based Views
The application uses Phlex components (`app/components/`) instead of traditional Rails views. This provides:
- Type-safe view composition
- Reusable UI components
- Better testing capabilities
- Ruby-native templating

### Authentication
Custom authentication implementation using:
- `bcrypt` for password hashing
- Session-based authentication
- User model with secure password

### Styling Approach
- Tailwind CSS v4 with new @import syntax
- Component-scoped styles where needed
- Responsive design patterns
- Dark mode ready (infrastructure in place)

### Date and Time Handling
- Application configured for Swiss timezone (Europe/Bern)
- Date format follows Swiss standard: DD.MM.YYYY or DD/MM/YYYY
- All date inputs use `Shared::DateInputComponent` for consistent formatting
- Date displays use `swiss_date_format` helper method for proper formatting
- HTML5 datetime-local inputs include format hints for user guidance

## Development Guidelines

### Working with Phlex Components
When creating or modifying UI components:
1. Place components in `app/components/`
2. Inherit from `ApplicationComponent`
3. Use semantic HTML and Tailwind utilities
4. Keep components focused and reusable
5. When combining SVG icons with text, wrap text in span elements for proper rendering

Example pattern:
```ruby
class ButtonComponent < ApplicationComponent
  def initialize(text:, variant: :primary)
    @text = text
    @variant = variant
  end

  def view_template
    button(class: button_classes) do
      svg_icon path_d: "...", class: "w-4 h-4 mr-2"
      span { @text }  # Wrap text in span for proper rendering
    end
  end

  private

  def button_classes
    # Tailwind classes based on variant
  end
end
```

### Database Considerations
- Always use migrations for schema changes
- PostgreSQL 17 specific features are available
- Use strong parameters in controllers
- Follow Rails conventions for associations

### Docker Development
- All commands should be run inside containers
- Use `docker compose exec web` for Rails commands
- Volumes persist gems and node_modules for performance
- Database runs in separate container

### Testing Best Practices
- Write request specs for new features
- Use system specs for UI interactions and user flows
- Use factories instead of fixtures
- Test user interactions, not implementation
- Keep specs focused and readable
- For delete buttons, use `button_to` with proper Turbo confirmation

## Current Application State

### ✅ Completed Features
- Rails 8 application scaffolding
- Docker containerization with compose
- PostgreSQL 17 database setup
- User authentication system (register/login/logout)
- Phlex component architecture
- Tailwind CSS v4 integration
- RSpec test suite setup
- Basic navigation and layout components
- Road trip management with route planning
- Packing list functionality with categories and progress tracking

### 🚧 In Progress
- None currently

### 📋 Planned Features
These features are planned but not yet implemented:
- Trip planning functionality
- Route mapping integration
- Accommodation booking
- Expense tracking
- Trip sharing and collaboration
- Photo galleries
- Offline mode support

## File Organization

```
app/
├── components/            # Phlex view components
│   ├── layouts/          # Layout components
│   ├── shared/           # Shared/common components
│   ├── road_trips/       # Road trip components
│   ├── routes/           # Route components
│   ├── packing_lists/    # Packing list components
│   └── packing_list_items/ # Packing list item components
├── controllers/          # Rails controllers
├── models/              # ActiveRecord models
└── javascript/          # Stimulus controllers

spec/
├── components/          # Component specs
├── requests/            # Request/integration specs
├── system/             # System/UI specs with Capybara
├── models/             # Model specs
└── factories/          # FactoryBot definitions
```

## Common Tasks

### Adding a New Feature
1. Create migration if database changes needed
2. Add model with validations and associations
3. Create Phlex components for UI
4. Add controller actions
5. Write request specs for API/controller logic
6. Write system specs for UI interactions
7. Add routes

### Modifying Styles
1. Edit `tailwind.config.js` for theme customization
2. Use Tailwind utilities in Phlex components
3. Run `npm run build-css` to rebuild in development

### Running Tests
```bash
# Run all tests
docker compose exec web rspec

# Run specific test types
docker compose exec web rspec spec/requests/     # Request specs
docker compose exec web rspec spec/system/      # System/UI specs
docker compose exec web rspec spec/models/      # Model specs

# Linting
docker compose exec web rubocop
```

### Dependency Management
The Docker setup automatically handles dependency installation:

1. **Standard Workflow**: `make down; make build; make up`
   - Always works reliably for dependency changes
   - The `bin/docker-entrypoint` script automatically runs `bundle install` if gems are missing
   - Volume caching preserves performance while ensuring dependencies are current

2. **How It Works**:
   - On container startup, `bundle check` verifies all gems are installed
   - If gems are missing, `bundle install` runs automatically
   - Same logic applies to npm dependencies with `node_modules` check

3. **Manual Dependency Installation**:
   ```bash
   docker compose run --rm web bundle install
   docker compose run --rm web npm install
   ```

## Performance Considerations

- Use Stimulus for JavaScript interactions (already set up)
- Leverage Turbo for SPA-like navigation
- Implement caching strategies with Solid Cache
- Use Active Job with Solid Queue for background jobs

## Security Notes

- Never commit secrets to the repository
- Use Rails credentials for sensitive configuration
- Implement strong parameters in all controllers
- Use CSRF protection (enabled by default)
- Sanitize user input in components

## Deployment Preparation

When ready for deployment:
1. Set up production credentials
2. Configure Kamal for deployment (gem already included)
3. Set up production database
4. Configure CDN for assets
5. Set up monitoring and error tracking

## Important Reminders

- Always run commands inside Docker containers
- Test changes with `docker compose up` before committing
- Follow Rails conventions and best practices
- Keep components small and focused
- Write tests for new functionality
- Update this file when making architectural changes

## Getting Help

- Rails 8 guides: https://guides.rubyonrails.org/
- Phlex documentation: https://www.phlex.fun/
- Tailwind CSS v4: https://tailwindcss.com/docs
- Docker Compose: https://docs.docker.com/compose/