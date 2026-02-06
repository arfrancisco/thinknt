# AGENTS.md - Thinkn't

## Project Overview

Thinkn't is an AI-powered quiz night generator. Users configure a quiz (theme, participants, question types, difficulty) via a React frontend, which sends a request to a Rails API backend. The backend uses OpenAI GPT-4o to generate quiz JSON, validated against a strict JSON Schema, then serves it back to a full-screen presenter UI.

## Monorepo Structure

```
thinknt/
├── backend/    # Ruby on Rails 7.1 API-only app
├── frontend/   # React 18 + Vite + Tailwind CSS SPA
```

These are independent apps with separate dependency management. There is no shared workspace tooling (no Turborepo, no Docker Compose).

## Architecture

- **Backend** (`backend/`): Rails API-only app. Single resource (`Quiz`) with async generation via `ActiveJob`. OpenAI integration in a service object. JSON Schema validation for all generated quiz data. SQLite in dev/test, PostgreSQL in production.
- **Frontend** (`frontend/`): Vite-powered React SPA. Two pages: quiz creation form and full-screen presenter mode. Communicates with backend via Axios. YouTube integration via `react-youtube` for audio/video questions.
- **Data flow**: Frontend POSTs quiz params → Backend creates Quiz record (status: `generating`) and enqueues `GenerateQuizJob` → Job calls `OpenaiQuizGenerator` → OpenAI returns JSON → Validated against schema → Quiz updated to `ready` → Frontend polls `GET /api/quizzes/:id` until ready → Redirects to presenter.

## Key Conventions

- No authentication or authorization — this is a single-user tool.
- Backend is strictly API-only (no views, no sessions, `config.api_only = true`).
- All API endpoints are namespaced under `/api/`.
- Quiz data structure is enforced by `config/quiz_schema.json` — any changes to quiz structure must update this schema.
- Environment variables: backend uses `.env` (loaded by `dotenv-rails`), frontend uses `.env.local` (loaded by Vite). Never commit these files.
- The `OPENAI_API_KEY` env var is required for quiz generation. Without it (or with an invalid key), the backend returns a 401-based generation failure.
- CORS is configured to allow `localhost:5173` (Vite dev server) and `localhost:3001`.

## Running the Project

```bash
# Backend
cd backend
bundle install
cp .env.example .env            # Then add your real OPENAI_API_KEY
bin/rails db:create db:migrate
bin/rails server                # http://localhost:3000

# Frontend
cd frontend
npm install
cp .env.example .env.local      # Defaults to http://localhost:3000
npm run dev                     # http://localhost:5173
```

## Setup Gotchas

- **`dotenv-rails` is required** — the backend relies on this gem to load `backend/.env` into the environment. Without it, `OPENAI_API_KEY` is empty and OpenAI returns a 401.
- **`bin/` scripts may have CRLF line endings** — if you get `env: ruby\r: No such file or directory`, fix with: `perl -pi -e 's/\r\n/\n/g' bin/*`
- **OpenAI API key must be valid with active billing** — a 401 error on quiz generation means the key is missing, invalid, or has no payment method attached.

## Running Tests

```bash
cd backend
bundle exec rspec
```

The frontend has no test suite currently.

## Important Files

- `backend/config/quiz_schema.json` — The source of truth for quiz data structure. Shared between OpenAI prompt generation, backend validation, and implicitly expected by frontend renderers.
- `backend/app/services/openai_quiz_generator.rb` — Core AI integration. Contains the system prompt, user prompt builder, and self-repair logic.
- `frontend/src/components/QuestionFrame.jsx` — Dispatcher that routes question types to the correct renderer component.

## Guidelines for Changes

- If you modify the quiz JSON structure, update `config/quiz_schema.json`, the OpenAI system prompt in `OpenaiQuizGenerator`, and any affected frontend renderers.
- Question types are: `text`, `audio`, `video`, `image`, `true_false`, `multiple_choice`. Each has a corresponding renderer in `frontend/src/components/renderers/`.
- Backend tests use RSpec with FactoryBot, WebMock, and shoulda-matchers. External HTTP requests are blocked in tests (`WebMock.disable_net_connect!`).
- Frontend uses functional components with hooks. No state management library — local state only via `useState`.
- Tailwind CSS for all styling. No component library. No CSS modules.
