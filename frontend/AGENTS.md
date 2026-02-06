# AGENTS.md - Frontend (React SPA)

## Overview

React 18 single-page application built with Vite. Two-page app: a quiz creation form and a full-screen presenter mode for running quiz nights. Communicates with the Rails backend API via Axios.

## Tech Stack

- React 18 with JSX (no TypeScript)
- Vite 5 (build tool and dev server)
- Tailwind CSS 3 (utility-first styling, no component library)
- React Router DOM 6 (client-side routing)
- Axios (HTTP client)
- react-youtube (YouTube iframe API wrapper)

## Project Structure

```
frontend/
├── src/
│   ├── main.jsx                                # Entry point, renders App
│   ├── App.jsx                                 # Router with two routes
│   ├── index.css                               # Tailwind imports
│   ├── pages/
│   │   ├── CreateQuizPage.jsx                  # Quiz config form + polling
│   │   └── PresenterPage.jsx                   # Full-screen quiz host UI
│   ├── components/
│   │   ├── QuestionFrame.jsx                   # Question type dispatcher
│   │   ├── AnswerReveal.jsx                    # Answer overlay modal
│   │   └── renderers/                          # One renderer per question type
│   │       ├── TextRenderer.jsx
│   │       ├── AudioRenderer.jsx               # YouTube audio-only (hidden player)
│   │       ├── VideoRenderer.jsx               # YouTube video player
│   │       ├── ImageRenderer.jsx               # Static image display
│   │       ├── TrueFalseRenderer.jsx           # True/False buttons
│   │       └── MultipleChoiceRenderer.jsx      # A/B/C/D choice cards
│   └── services/
│       └── api.js                              # Axios client (createQuiz, getQuiz, regenerateQuestion)
├── index.html
├── package.json
├── vite.config.js
├── tailwind.config.js
└── postcss.config.js
```

## Routes

| Path                | Component         | Description                  |
|---------------------|-------------------|------------------------------|
| `/`                 | CreateQuizPage    | Quiz creation form           |
| `/presenter/:quizId`| PresenterPage    | Full-screen quiz presenter   |

## Key Patterns

### State Management

No external state library. All state is local via `useState`. Quiz data is fetched and held in the page components.

### Quiz Creation Flow

1. `CreateQuizPage` collects: theme, participants (name/age/country), countries, question types, rounds, questions per round, brainrot level.
2. On submit, POSTs to `/api/quizzes`.
3. Polls `GET /api/quizzes/:id` every 2 seconds (max 60 attempts / 2 minutes).
4. On `status: "ready"`, navigates to `/presenter/:quizId`.
5. On `status: "failed"`, displays error inline.

### Presenter Mode

- `PresenterPage` fetches quiz data once on mount.
- Tracks `currentRoundIndex` and `currentQuestionIndex` for navigation.
- Keyboard shortcuts: **Space** toggles answer reveal, **Right Arrow** advances to next question.
- `QuestionFrame` dispatches to the correct renderer based on `question.type`.
- `AnswerReveal` is a full-screen overlay showing the answer, correct choice (for MCQ/T-F), and optional explanation.

### Question Renderers

Each renderer receives a `question` prop and handles its specific type:

- **TextRenderer**: Displays the prompt only (answer shown via AnswerReveal).
- **AudioRenderer**: Hidden YouTube player (`height: 0, width: 0`). Play/Stop controls with replay limits and countdown timer. Anti-spoiler support.
- **VideoRenderer**: Visible YouTube player (854x480). Play/Stop controls with replay limits. CSS overlay hides YouTube title bar for anti-spoiler.
- **ImageRenderer**: Displays image from URL.
- **TrueFalseRenderer**: Two large True/False buttons (display only, not interactive for scoring).
- **MultipleChoiceRenderer**: A/B/C/D choice cards (display only).

### Anti-Spoiler System

Audio and video renderers implement anti-spoiler controls from the quiz data:
- `anti_spoiler.max_replays`: Limits number of times media can be replayed.
- `anti_spoiler.auto_stop`: Auto-stops playback at `end_sec`.
- `anti_spoiler.hide_titles`: Hides YouTube title bar (video only, via CSS overlay).

State resets when the question changes (tracked by `question.id`).

### API Client

`src/services/api.js` exports three functions:
- `createQuiz(payload)` — POST `/api/quizzes`
- `getQuiz(quizId)` — GET `/api/quizzes/:id`
- `regenerateQuestion(quizId, scope, questionId, notes)` — POST `/api/quizzes/:id/regenerate`

Base URL comes from `VITE_API_URL` env var, defaults to `http://localhost:3000`.

## Environment Variables

| Variable      | Required | Description                          |
|---------------|----------|--------------------------------------|
| VITE_API_URL  | No       | Backend API URL (default: `http://localhost:3000`) |

Copy `.env.example` to `.env.local` and adjust if needed. Vite loads `.env.local` automatically; only variables prefixed with `VITE_` are exposed to client code.

## Development

```bash
npm install
npm run dev       # http://localhost:5173
npm run build     # Production build to dist/
npm run lint      # ESLint
```

## Testing

No test suite is configured. There are no unit or integration tests for the frontend.

## Guidelines

- All styling uses Tailwind utility classes. No CSS modules, no styled-components, no component library.
- Components are functional with hooks. No class components.
- The quiz data structure is defined by the backend's `config/quiz_schema.json`. Frontend renderers expect this exact shape — particularly `question.type`, `question.media`, `question.choices`, `question.correct_choice_index`, `question.answer.display`, and `question.anti_spoiler`.
- When adding a new question type: create a new renderer in `src/components/renderers/`, add a case to `QuestionFrame`'s switch statement, and update the backend schema + OpenAI prompt.
- The `style jsx` blocks in `AnswerReveal` and `VideoRenderer` use inline `<style>` tags for animations and YouTube title hiding — these are not actual CSS-in-JS (no runtime).
- YouTube player state codes: `1` = playing, `2` = paused, `0` = ended.
