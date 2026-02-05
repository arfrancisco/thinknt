#!/bin/bash

echo "==============================================="
echo "Thinkn't Backend Test Runner"
echo "==============================================="
echo ""

# Navigate to backend directory
cd /home/alain/thinknt/backend

echo "Step 1: Installing Ruby dependencies..."
bundle install

echo ""
echo "Step 2: Setting up test database..."
RAILS_ENV=test rails db:create
RAILS_ENV=test rails db:migrate

echo ""
echo "Step 3: Running RSpec tests..."
echo "==============================================="
bundle exec rspec --format documentation

echo ""
echo "==============================================="
echo "Test run complete!"
echo "==============================================="
