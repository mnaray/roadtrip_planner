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

# Expose port 3000
EXPOSE 3000

# Default command - can be overridden by docker-compose
CMD ["bash"]