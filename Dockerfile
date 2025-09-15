FROM ruby:3.4-slim

# Install build dependencies first including curl
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    libyaml-dev \
    postgresql-client \
    git \
    curl \
    ca-certificates \
    gnupg \
    lsb-release \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome for system tests
RUN curl -sSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update -qq \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x with npm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /bin/bash rails && \
    mkdir -p /app && \
    chown -R rails:rails /app

WORKDIR /app

# Copy dependency files first for better caching
COPY --chown=rails:rails Gemfile* package*.json ./

# Switch to rails user
USER rails

# Install gems and npm dependencies
RUN bundle install
RUN npm install

# Copy the rest of the application
COPY --chown=rails:rails . .

# Build Tailwind CSS
RUN npm run build-css:production

# Expose port 3000
EXPOSE 3000

# Default command starts Puma
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]