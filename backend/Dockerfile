FROM ruby:3.2-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    libsqlite3-dev \
    libyaml-dev \
    && rm -rf /var/lib/apt/lists/*

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3 && \
    rm -rf ~/.bundle/cache

# Copy application code
COPY . .

# Fix potential CRLF line endings in bin scripts
RUN sed -i 's/\r$//' bin/*

# Ensure binstubs are executable
RUN chmod +x bin/*

ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=1

EXPOSE 3000

# Migrate and then start the server
CMD ["sh", "-c", "bin/rails db:prepare && bin/rails server -b 0.0.0.0 -p 3000"]
