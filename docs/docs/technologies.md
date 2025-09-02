# Technology Stack

Roadtrip Planner is built with modern web technologies, emphasizing performance, maintainability, and developer experience.

## Core Technologies

### Backend Framework
- **Rails**: 8.0.2.1
  - Latest stable version with new features
  - Solid Cache, Solid Queue, and Solid Cable for improved performance
  - Modern asset pipeline with Propshaft
  - Enhanced security and performance improvements

### Runtime & Language
- **Ruby**: 3.4.x
  - Latest stable Ruby version
  - Improved performance and memory usage
  - Enhanced syntax features and developer experience

### Database
- **PostgreSQL**: 17
  - Latest stable version
  - Advanced JSON support
  - Full-text search capabilities
  - Robust ACID compliance

## Frontend Stack

### View Layer
- **Phlex**: Component-based Ruby views
  - Type-safe view composition
  - Reusable UI components
  - Better testing capabilities than ERB
  - Ruby-native templating without separate template languages

### Styling
- **Tailwind CSS**: v4
  - New @import syntax for cleaner configuration
  - Utility-first CSS framework
  - Responsive design utilities
  - Dark mode support infrastructure
  - Custom color palette and animations

### JavaScript
- **Importmaps**: No build step required
  - Native ES modules
  - Simplified dependency management
  - Fast development iteration

- **Stimulus.js**: Modest JavaScript framework
  - Progressive enhancement approach
  - HTML-centric development
  - Minimal JavaScript footprint
  - Excellent Rails integration

- **Turbo**: Hotwire's SPA-like page accelerator
  - Fast navigation without full page reloads
  - Real-time features with Turbo Streams
  - Native mobile app feel

## Authentication & Security

### Authentication
- **Custom Implementation**: Secure, lightweight solution
  - **bcrypt**: Password hashing (~> 3.1.7)
  - Session-based authentication
  - Secure password validation patterns
  - Username uniqueness and validation

### Security Tools
- **Brakeman**: Static security analysis
  - Automated vulnerability scanning
  - Rails-specific security checks
  - CI/CD integration for continuous monitoring

## Testing Framework

### Test Suite
- **RSpec**: ~> 8.0
  - Behavior-driven development (BDD)
  - Descriptive test syntax
  - Comprehensive matchers and helpers

### Test Support
- **FactoryBot**: Test data generation
  - Clean, maintainable test fixtures
  - Flexible data creation patterns
  - Association handling

- **Faker**: Realistic test data
  - Dynamic test data generation
  - Locale-aware data generation

### System Testing
- **Capybara**: Integration testing
  - Browser automation for end-to-end tests
  - User interaction simulation

- **Selenium WebDriver**: Browser automation
  - Cross-browser testing support
  - JavaScript execution in tests

## Development Tools

### Containerization
- **Docker**: Consistent development environment
  - Ruby 3.4-slim base image
  - Non-root user for security
  - Optimized layer caching

- **Docker Compose**: Multi-service orchestration
  - PostgreSQL service configuration
  - Volume management for development
  - Environment variable management

### Code Quality
- **RuboCop**: Ruby style guide enforcement
  - Rails Omakase configuration
  - Consistent code formatting
  - Best practice enforcement

### Asset Pipeline
- **Propshaft**: Modern Rails asset pipeline
  - Simplified asset management
  - HTTP/2 optimization
  - CDN-ready asset handling

## Deployment & Infrastructure

### Deployment
- **Kamal**: Modern deployment solution
  - Docker-based deployments
  - Zero-downtime deployments
  - Multi-server support

- **Thruster**: HTTP asset optimization
  - Asset caching and compression
  - X-Sendfile acceleration for Puma
  - Performance optimization

### Background Processing
- **Solid Queue**: Database-backed job processing
  - Reliable job execution
  - No Redis dependency
  - Built-in Rails 8 support

### Caching
- **Solid Cache**: Database-backed caching
  - Simplified cache management
  - No separate cache server required
  - Rails 8 native integration

### Real-time Features
- **Solid Cable**: WebSocket connections
  - Database-backed Action Cable adapter
  - Simplified real-time features
  - No Redis dependency

## Development Dependencies

### Package Management
- **Bundler**: Ruby gem management
  - Dependency resolution
  - Lock file for reproducible builds

- **npm**: JavaScript package management
  - Tailwind CSS and plugins
  - Build tool dependencies

### Node.js Tools
- **Node.js**: 20.x LTS
  - Stable, long-term support version
  - Required for Tailwind CSS compilation

- **Tailwind CSS Plugins**:
  - `@tailwindcss/forms`: Form styling utilities
  - `@tailwindcss/typography`: Typography utilities

## Version Requirements

| Technology | Version | Purpose |
|------------|---------|---------|
| Ruby | 3.4.x | Runtime environment |
| Rails | 8.0.2.1 | Web framework |
| PostgreSQL | 17 | Database |
| Node.js | 20.x LTS | Frontend tooling |
| Docker | Latest | Containerization |
| Docker Compose | v2+ | Orchestration |

## Architecture Benefits

This technology stack provides:

- **Modern Development Experience**: Latest tools and frameworks
- **Performance**: Optimized for speed and efficiency
- **Maintainability**: Clear patterns and conventions
- **Scalability**: Built for growth and expansion
- **Security**: Best practices and secure defaults
- **Developer Productivity**: Fast feedback loops and debugging tools
- **Deployment Simplicity**: Container-based deployment with modern tools

## Migration Path

The application is designed to be forward-compatible:

- **Rails 8+**: Ready for future Rails versions
- **Ruby 3.4+**: Compatible with upcoming Ruby releases
- **Docker**: Container-first approach for any deployment target
- **Modern JavaScript**: Uses standard ES modules for future compatibility