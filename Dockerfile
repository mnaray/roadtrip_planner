FROM ruby:3.4-slim

# Install build dependencies
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    libyaml-dev \
    nodejs \
    postgresql-client \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /bin/bash rails && \
    mkdir -p /app && \
    chown -R rails:rails /app

WORKDIR /app

# Copy Gemfile first for better caching
COPY --chown=rails:rails Gemfile* ./

# Switch to rails user
USER rails

# Install gems
RUN bundle install

# Copy the rest of the application
COPY --chown=rails:rails . .

# Expose port 3000
EXPOSE 3000

# Default command starts Puma
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]