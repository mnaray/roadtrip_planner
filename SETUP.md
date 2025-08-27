# Tailwind CSS v4 + Rails 8 + Phlex Setup Guide

This project uses Tailwind CSS v4 with Rails 8 and Phlex components in a Docker environment.

## Quick Start

1. **Copy environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Build and start the application:**
   ```bash
   make build
   make up
   ```

3. **Set up the database:**
   ```bash
   make migrate
   ```

4. **Visit the application:**
   Open http://localhost:3000 in your browser

## Tailwind CSS Development

### Building CSS

- **Production build:** `make css-build`
- **Watch for changes:** `make css-watch`

The CSS files:
- **Source:** `app/assets/stylesheets/application.tailwind.css`
- **Output:** `app/assets/stylesheets/application.css`

### Tailwind CSS Features Used

1. **Modern Tailwind CSS v3.4.7** with latest features
2. **Custom color palette** with primary and accent colors
3. **Custom animations** (fade-in, slide-up, bounce-in)
4. **Custom utility classes** in `@layer utilities`
5. **Modern CSS features** like backdrop-filter and gradients
6. **Animation delays** for staggered effects

### Component Architecture

The application uses Phlex components:
- `ApplicationLayout` - Main layout with Tailwind classes
- `WelcomeSection` - Hero section with animations
- `HomePage` - Page composition

### Styling Approach

1. **Utility-first** with Tailwind classes
2. **Component-scoped** styling within Phlex components
3. **Modern CSS features** like gradients, backdrop-filter, and animations
4. **Responsive design** with Tailwind's responsive prefixes
5. **Custom animations** for enhanced UX

## Available Make Commands

- `make build` - Build Docker images
- `make up` - Start services
- `make down` - Stop services  
- `make bash` - Open shell in web container
- `make console` - Open Rails console
- `make migrate` - Run database migrations
- `make css-build` - Build Tailwind CSS for production
- `make css-watch` - Watch Tailwind CSS changes
- `make test` - Run tests

## Docker Architecture

- **Node.js 20.x** for Tailwind CSS compilation
- **Ruby 3.4** with Rails 8
- **PostgreSQL 17** database
- **Volumes** for gem and node_modules caching
- **Hot reloading** for development

## Troubleshooting

### CSS Not Loading

1. Ensure Tailwind CSS is compiled:
   ```bash
   make css-build
   ```

2. Check if node_modules is installed:
   ```bash
   make bash
   npm install
   ```

### Container Issues

1. Rebuild containers:
   ```bash
   make down
   make build
   make up
   ```

2. Check logs:
   ```bash
   make logs
   ```

## Production Deployment

The Dockerfile includes production-ready CSS builds:
- CSS is compiled during Docker build
- Optimized with `--minify` flag
- Assets served via Rails Propshaft

## Technology Stack

- **Rails 8.0.2.1** with Propshaft
- **Tailwind CSS v3.4.7** with modern features  
- **Phlex** for component-based views
- **Docker** for containerized development
- **PostgreSQL 17** database
- **Node.js 20** for asset compilation

## Features Implemented

- Beautiful gradient backgrounds with subtle animations
- Glass-morphism effects using backdrop-filter
- Responsive design with mobile-first approach
- Custom color palette with primary and accent colors
- Smooth animations with staggered timing
- Modern typography using Inter font
- Interactive hover effects and transitions
- Accessibility-focused design with proper focus states