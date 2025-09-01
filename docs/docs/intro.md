# Welcome to Roadtrip Planner Documentation

Roadtrip Planner is a **Rails 8 application** for planning and managing road trips, built with modern web technologies and containerized for easy development.

## What is Roadtrip Planner?

This application provides users with the ability to:

- **Plan Road Trips**: Create and organize multi-day road trips with detailed routes
- **Manage Routes**: Define starting locations, destinations, and timing for each leg of the journey  
- **Track Progress**: Monitor trip progress and manage route details
- **Export Data**: Generate GPX files for use with GPS devices and mapping applications

## Key Features

✅ **User Authentication** - Secure registration and login system  
✅ **Component-Based Architecture** - Built with Phlex components for maintainable, reusable UI  
✅ **Modern Styling** - Tailwind CSS v4 with responsive design  
✅ **Containerized Development** - Docker-based development environment  
✅ **PostgreSQL Database** - Robust data storage with proper relationships  
✅ **Comprehensive Testing** - RSpec test suite with FactoryBot  

## Technology Stack

- **Backend**: Rails 8.0.2.1 with Ruby 3.4.x
- **Database**: PostgreSQL 17
- **Frontend**: Phlex components, Tailwind CSS v4, Stimulus.js
- **Authentication**: Custom implementation with bcrypt
- **Testing**: RSpec with FactoryBot
- **Containerization**: Docker & Docker Compose

## Quick Start

Get up and running in minutes:

```bash
git clone https://github.com/mnaray/roadtrip_planner.git
cd roadtrip_planner
docker compose up
```

Open [http://localhost:3000](http://localhost:3000) to view the application.

## Documentation Structure

This documentation is organized into several key sections:

- **Getting Started**: Set up your development environment and learn about contributing
- **Architecture**: Understand the application's design, patterns, and CI/CD pipeline
- **Models**: Deep dive into the data layer with User, RoadTrip, and Route models
- **Services**: Learn about business logic services for calculations and data export
- **Components**: Explore the Phlex component system with examples and usage patterns
- **Development**: Testing procedures and deployment instructions

## Contributing

We welcome contributions! Please see our [Contributing Guide](./contributing.md) to get started.

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/mnaray/roadtrip_planner/blob/main/LICENSE) file for details.