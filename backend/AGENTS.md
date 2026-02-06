# AGENTS.md - Backend (Rails API)

## Overview

Ruby on Rails 7.1 API-only application. Manages quiz creation, async generation via OpenAI, and serving quiz data to the frontend.

## Tech Stack

- Ruby ~> 3.0, Rails ~> 7.1
<<<<<<< HEAD
- SQLite for all environments (no PostgreSQL)
=======
- SQLite (dev/test), PostgreSQL (production)
>>>>>>> 071a39f (fix merge)
- `ruby-openai` gem for OpenAI API
- `json-schema` gem for quiz data validation
- `dotenv-rails` for loading `.env` in dev/test
- Puma web server
- ActiveJob for background processing (inline adapter in dev, no Redis/Sidekiq)
<<<<<<< HEAD
- Docker: `ruby:3.2-slim` base image, deployed to Fly.io
=======
>>>>>>> 071a39f (fix merge)

## Project Structure

```
backend/
├── app/
│   ├── controllers/api/quizzes_controller.rb   # REST endpoints: create, show, regenerate
│   ├── models/quiz.rb                          # Quiz model with enum status, schema validation
│   ├── services/openai_quiz_generator.rb       # OpenAI integration & prompt engineering
│   └── jobs/generate_quiz_job.rb               # Async quiz generation
├── config/
│   ├── quiz_schema.json                        # JSON Schema (source of truth for quiz structure)
│   ├── routes.rb                               # API-namespaced routes
│   ├── initializers/cors.rb                    # CORS config for frontend origins
│   └── initializers/openai.rb                  # OpenAI client config
├── db/
│   ├── schema.rb                               # Single table: quizzes
│   └── migrate/
├── spec/                                       # RSpec test suite
│   ├── requests/api/quizzes_spec.rb
│   ├── services/openai_quiz_generator_spec.rb
│   ├── jobs/generate_quiz_job_spec.rb
│   ├── models/quiz_spec.rb
│   └── factories/quizzes.rb
```

## Database

Single table: `quizzes`

| Column            | Type     | Notes                                      |
|-------------------|----------|---------------------------------------------|
| theme             | string   | Required                                    |
| status            | integer  | Enum: `generating` (0), `ready` (1), `failed` (2) |
| quiz_data         | json     | Full generated quiz (validated against schema) |
| generation_params | json     | Saved input params for regeneration         |
| error_message     | text     | Set on failure                              |

## API Endpoints

| Method | Path                          | Action      | Description                    |
|--------|-------------------------------|-------------|--------------------------------|
| POST   | `/api/quizzes`                | create      | Create quiz, enqueue generation |
| GET    | `/api/quizzes/:id`            | show        | Get quiz status and data        |
| POST   | `/api/quizzes/:id/regenerate` | regenerate  | Re-run generation with saved params |

## Key Patterns

### Quiz Generation Flow

1. Controller receives params, creates `Quiz` record with `status: :generating`, saves `generation_params`.
2. `GenerateQuizJob` is enqueued with `quiz_id` and params.
3. Job calls `OpenaiQuizGenerator.generate(params)`.
4. Generator builds a system prompt (embedding the JSON schema) and a user prompt (with theme, participants, constraints).
5. OpenAI response is parsed and validated against `config/quiz_schema.json`.
6. If validation fails, a single repair attempt is made (sends errors back to OpenAI).
7. On success: quiz updated to `ready` with `quiz_data`. On failure: updated to `failed` with `error_message`.

### Service Object Pattern

`OpenaiQuizGenerator` is the only service object. It follows:
- Class method `.generate(params)` delegates to instance.
- Instance method `#generate` orchestrates the flow.
- Private methods for prompt building, API calls, parsing, and validation.
- Custom `GenerationError` exception class.

### Parameter Handling

The controller uses `generation_params` (a plain hash) rather than strong params for the generation payload, because the params include nested arrays/objects (participants, countries, allowed_types). The hash is saved to the quiz record for regeneration support.

## Testing

```bash
bundle exec rspec
```

- **Framework**: RSpec with `rspec-rails`
- **Factories**: FactoryBot (`spec/factories/`)
- **HTTP mocking**: WebMock — all external requests are blocked (`WebMock.disable_net_connect!`)
- **Job testing**: `ActiveJob::TestHelper` included; jobs use `:test` adapter
- **Matchers**: shoulda-matchers for model validations

OpenAI API calls are stubbed via WebMock in all specs. The `spec/fixtures/sample_quiz.json` file provides a valid quiz fixture for generator tests.

## Environment Variables

<<<<<<< HEAD
| Variable         | Required | Description                                                              |
|------------------|----------|--------------------------------------------------------------------------|
| OPENAI_API_KEY   | Yes      | OpenAI API key                                                           |
| SECRET_KEY_BASE  | Yes (prod) | Rails secret key (generate with `openssl rand -hex 64`)               |
| CORS_ORIGINS     | No       | Comma-separated allowed origins (default: `localhost:5173,3001,8080`)    |
| RAILS_ENV        | No       | Defaults to `development`; Dockerfile sets `production`                  |

For local dev, copy `.env.example` to `.env` and fill in values. Never commit `.env`.

The `.env` file is loaded by `dotenv-rails` (dev/test only). In production (Docker/Fly.io), set env vars via `docker run -e` or `fly secrets set`. If `OPENAI_API_KEY` is missing or invalid, quiz generation will fail with a 401 error from OpenAI.

## Docker

```bash
docker build -t thinknt-backend .
docker run --rm -d -p 3001:3000 \
  -e OPENAI_API_KEY="sk-..." \
  -e SECRET_KEY_BASE="$(openssl rand -hex 64)" \
  thinknt-backend
```

The Dockerfile:
- Uses `ruby:3.2-slim` with `build-essential`, `libsqlite3-dev`, `libyaml-dev`
- Excludes `development` and `test` gem groups
- Fixes CRLF line endings in `bin/` scripts automatically (`sed -i 's/\r$//' bin/*`)
- Sets `RAILS_ENV=production` and `RAILS_LOG_TO_STDOUT=1`
- Runs `db:prepare` at container startup (not build time) so the SQLite file is created at runtime
- For Fly.io, the SQLite database should live on a persistent volume

## Setup Gotchas

- **CRLF line endings in `bin/` scripts**: The `bin/rails`, `bin/rake`, `bin/setup`, and `bin/server` scripts may have Windows-style CRLF line endings, causing `env: ruby\r: No such file or directory`. Fix with: `perl -pi -e 's/\r\n/\n/g' bin/*` (the Dockerfile handles this automatically).
- **dotenv-rails is essential**: Without it, Rails won't load the `.env` file and `ENV["OPENAI_API_KEY"]` will be empty. The OpenAI initializer (`config/initializers/openai.rb`) defaults to an empty string, which causes a silent 401 failure at generation time rather than a startup error.
- **CORS**: The `CORS_ORIGINS` env var must include the frontend's origin. If the frontend is on a different port or domain and API requests silently fail (no request hits the backend logs), CORS is the likely cause.
- **SQLite in production**: Rails will log a warning about SQLite in production. This is expected and harmless for this single-user app.
=======
| Variable        | Required | Description          |
|-----------------|----------|----------------------|
| OPENAI_API_KEY  | Yes      | OpenAI API key       |
| RAILS_ENV       | No       | Defaults to development |

Copy `.env.example` to `.env` and fill in values. Never commit `.env`.

The `.env` file is loaded by `dotenv-rails` (dev/test only). In production, set env vars through your hosting platform. If `OPENAI_API_KEY` is missing or invalid, quiz generation will fail with a 401 error from OpenAI.

## Setup Gotchas

- **CRLF line endings in `bin/` scripts**: The `bin/rails`, `bin/rake`, `bin/setup`, and `bin/server` scripts may have Windows-style CRLF line endings, causing `env: ruby\r: No such file or directory`. Fix with: `perl -pi -e 's/\r\n/\n/g' bin/*`
- **dotenv-rails is essential**: Without it, Rails won't load the `.env` file and `ENV["OPENAI_API_KEY"]` will be empty. The OpenAI initializer (`config/initializers/openai.rb`) defaults to an empty string, which causes a silent 401 failure at generation time rather than a startup error.
>>>>>>> 071a39f (fix merge)

## Guidelines

- All responses are JSON. No HTML views, no Jbuilder templates used in practice (gem is included but controller renders inline JSON).
- The `quiz_schema.json` is embedded in the OpenAI system prompt. If you change the schema, the AI will automatically receive the updated structure.
- `Quiz.compute_audience_stats` is a class method that computes age statistics from participants — used in prompt building.
- The model's `validate_quiz_schema` and `quiz_schema_errors` methods can be used to check quiz data outside of the generator.
- When adding new question types, update: the schema's `type` enum, the system prompt instructions in `OpenaiQuizGenerator`, and ensure the frontend has a matching renderer.
