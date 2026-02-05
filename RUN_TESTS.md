# Quick Test Run Script

## To run the tests, open WSL terminal and execute:

```bash
cd /home/alain/thinknt
chmod +x run_tests.sh
./run_tests.sh
```

## Or run commands manually:

```bash
cd /home/alain/thinknt/backend

# Install dependencies
bundle install

# Setup test database
RAILS_ENV=test rails db:create
RAILS_ENV=test rails db:migrate

# Run all tests
bundle exec rspec

# Run with documentation format
bundle exec rspec --format documentation

# Run specific test files
bundle exec rspec spec/models/quiz_spec.rb
bundle exec rspec spec/services/openai_quiz_generator_spec.rb
bundle exec rspec spec/requests/api/quizzes_spec.rb
bundle exec rspec spec/jobs/generate_quiz_job_spec.rb
```

## Expected Output:

All tests should pass with output like:

```
Quiz
  validations
    validates presence of theme
    validates presence of status
  status enum
    has generating status
    has ready status
    has failed status
  #validate_quiz_schema
    validates correct schema
    returns false for missing required fields
    ...

Finished in 0.5 seconds (files took 2 seconds to load)
25 examples, 0 failures
```

## Test Coverage:

- ✅ 25+ test examples
- ✅ Model validations and methods
- ✅ OpenAI service with mocked API calls
- ✅ API endpoints (POST, GET)
- ✅ Background job processing
- ✅ Error handling

## Troubleshooting:

If bundle install fails:
```bash
gem install bundler
bundle install
```

If database creation fails:
```bash
sudo apt-get install sqlite3 libsqlite3-dev
```

If Rails is not found:
```bash
gem install rails -v 7.1.0
```
