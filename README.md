# Roadtrip Planner

A Ruby on Rails application for planning multi-day road trips with multiple routes and stops. Export your routes to GPX files for use with navigation apps.

## Features

- 🗺️ **Multi-day Trip Planning**: Organize your road trips across multiple days
- 🛣️ **Route Management**: Create detailed routes for each day of your trip
- 📍 **Multiple Stops**: Add multiple waypoints to each route with coordinates
- 📱 **GPX Export**: Export routes to GPX format for use with navigation apps
- 🎨 **Modern UI**: Built with Phlex 2 and Tailwind CSS 4
- 🐳 **Docker Support**: Easy development setup with Docker

## Tech Stack

- **Ruby on Rails 8** - Web framework
- **PostgreSQL** - Database
- **Phlex 2** - UI components
- **Tailwind CSS 4** - Styling
- **Docker** - Development environment
- **GPX gem** - GPX file generation

## Development Setup

### Prerequisites

- Docker and Docker Compose
- Git

### Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/mnaray/roadtrip_planner.git
   cd roadtrip_planner
   ```

2. **Build and start the development environment**
   ```bash
   docker compose build
   docker compose up
   ```

3. **Set up the database**
   ```bash
   # In another terminal
   docker compose exec web rails db:create db:migrate
   ```

4. **Access the application**
   - Open your browser to [http://localhost:3000](http://localhost:3000)

### Development Commands

**Run Rails commands:**
```bash
docker compose exec web rails console
docker compose exec web rails generate model MyModel
docker compose exec web rails db:migrate
```

**Run tests:**
```bash
docker compose exec web rails test
```

**Install new gems:**
1. Add gem to `Gemfile`
2. Run: `docker compose exec web bundle install`
3. Restart: `docker compose restart web`

### Database Schema

The application uses three main models:

- **Trip**: Represents a multi-day road trip
  - `name`, `description`, `start_date`, `end_date`
  - Has many routes

- **Route**: Represents a single day's route within a trip
  - `name`, `day_number`, `total_distance`, `estimated_duration_minutes`, `notes`
  - Belongs to trip, has many stops

- **Stop**: Represents waypoints along a route
  - `name`, `address`, `latitude`, `longitude`, `order`, `arrival_time`, `departure_time`, `notes`
  - Belongs to route

## Usage

### Planning a Trip

1. **Create a Trip**: Start by creating a new trip with a name, description, and date range
2. **Add Routes**: Add routes for each day of your trip
3. **Add Stops**: Add waypoints to each route with GPS coordinates
4. **Export GPX**: Download GPX files for each route to use with your preferred navigation app

### GPX Export

Routes can be exported as GPX (GPS Exchange Format) files that are compatible with:
- Google Maps
- Apple Maps
- Garmin devices
- TomTom devices
- Most smartphone navigation apps

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
