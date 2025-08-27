# Use a pre-built Ruby/Rails image
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

# Configure gem to not verify SSL (development only)
RUN echo "gem: --no-document --source http://rubygems.org/" > ~/.gemrc

# Install Rails without SSL verification
RUN gem install rails -v "8.0.2.1" --no-document --source http://rubygems.org/ || \
    gem install rails -v "8.0.2.1" --no-document

# Copy application files
COPY . .

# Configure bundler for development
RUN bundle config set --global force_ruby_platform true && \
    bundle config set --global disable.ssl_verify true

# Install gems
RUN bundle install || true

# Expose port 3000
EXPOSE 3000

# Start the Rails server
CMD ["rails", "server", "-b", "0.0.0.0"]