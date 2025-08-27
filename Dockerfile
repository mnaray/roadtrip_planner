# Use official Ruby image
FROM ruby:3.2.3

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y \
      build-essential \
      postgresql-client \
      nodejs \
      npm \
      git && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Set working directory
WORKDIR /app

# Copy application code
COPY . .

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Try to install gems during build, but don't fail if network is restricted
RUN bundle config set --local without 'development test' && \
    (timeout 60 bundle install || echo "Network restricted - gems will be installed at startup") || true

# Create necessary directories
RUN mkdir -p tmp/pids log

# Ensure bin files are executable
RUN chmod +x bin/rails bin/rake

# Expose port 3000
EXPOSE 3000

# Use entrypoint script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]