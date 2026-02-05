# Thinkn't - AI-Powered Quiz Night Generator

An interactive quiz night platform powered by OpenAI that generates engaging quizzes with multiple question types including text, audio, video, image, true/false, and multiple choice questions.

## Architecture

- **Backend**: Ruby on Rails API (RESTful, JSON responses)
- **Frontend**: React with Vite + Tailwind CSS
- **AI**: OpenAI GPT-4 for quiz generation
- **Database**: SQLite (dev), PostgreSQL (production on Heroku)

## Features

- AI-generated quizzes based on themes and audience
- Full-screen Presenter Mode for quiz hosting
- Multiple question types: text, audio, video, image, true/false, multiple choice
- YouTube integration for audio/video questions
- Anti-spoiler controls (replay limits, auto-stop)
- Progressive difficulty (easy → medium → hard)
- Brainrot level customization

## Setup Instructions

### Backend (Rails API)

1. **Install Dependencies**

```bash
cd backend
bundle install
```

2. **Configure Environment**

Create a `.env` file in the `backend` directory:

```
OPENAI_API_KEY=your_openai_api_key_here
RAILS_ENV=development
```

3. **Setup Database**

```bash
rails db:create
rails db:migrate
```

4. **Start Server**

```bash
rails server
```

The API will be available at `http://localhost:3000`

### Frontend (React)

1. **Install Dependencies**

```bash
cd frontend
npm install
```

2. **Configure Environment**

Create a `.env.local` file in the `frontend` directory:

```
VITE_API_URL=http://localhost:3000
```

3. **Start Development Server**

```bash
npm run dev
```

The frontend will be available at `http://localhost:5173`

## Usage

1. Open `http://localhost:5173` in your browser
2. Fill in the quiz creation form:
   - Enter a theme (e.g., "90s Pop Culture", "Space Exploration")
   - Add participants with their names, ages, and countries
   - Select target countries for content relevance
   - Choose question types to include
   - Set number of rounds and questions per round
   - Select brainrot level (low/medium/high)
3. Click "Generate Quiz" and wait for AI generation
4. You'll be redirected to Presenter Mode automatically
5. Use keyboard shortcuts:
   - **Space**: Reveal/hide answer
   - **Right Arrow**: Next question

## Project Structure

### Backend

```
backend/
├── app/
│   ├── controllers/api/quizzes_controller.rb  # API endpoints
│   ├── models/quiz.rb                          # Quiz model
│   ├── services/openai_quiz_generator.rb      # OpenAI integration
│   └── jobs/generate_quiz_job.rb              # Background generation
├── config/
│   ├── quiz_schema.json                        # JSON Schema validator
│   └── initializers/openai.rb                  # OpenAI config
└── db/
    └── migrate/                                 # Database migrations
```

### Frontend

```
frontend/src/
├── pages/
│   ├── CreateQuizPage.jsx                      # Quiz creation form
│   └── PresenterPage.jsx                       # Full-screen presenter
├── components/
│   ├── QuestionFrame.jsx                       # Type dispatcher
│   ├── AnswerReveal.jsx                        # Answer modal
│   └── renderers/                              # Question type renderers
│       ├── TextRenderer.jsx
│       ├── AudioRenderer.jsx
│       ├── VideoRenderer.jsx
│       ├── ImageRenderer.jsx
│       ├── TrueFalseRenderer.jsx
│       └── MultipleChoiceRenderer.jsx
└── services/
    └── api.js                                   # API client
```

## API Endpoints

### POST /api/quizzes

Create a new quiz and start generation.

**Request:**
```json
{
  "theme": "90s Pop Culture",
  "participants": [{"name": "Alice", "age": 28, "country": "US"}],
  "countries": ["US", "UK"],
  "rounds": 3,
  "questions_per_round": 7,
  "brainrot_level": "medium",
  "allowed_types": ["text", "audio", "video", "image", "true_false", "multiple_choice"]
}
```

**Response:**
```json
{
  "quiz_id": "1",
  "status": "generating"
}
```

### GET /api/quizzes/:id

Get quiz status and data.

**Response (generating):**
```json
{
  "id": "1",
  "status": "generating",
  "theme": "90s Pop Culture"
}
```

**Response (ready):**
```json
{
  "id": "1",
  "status": "ready",
  "theme": "90s Pop Culture",
  "quiz": {
    "id": "qz_123",
    "title": "Ultimate 90s Pop Culture Quiz",
    "rounds": [...]
  }
}
```

## JSON Schema

All quizzes are validated against a strict JSON Schema to ensure:
- Required fields are present
- Question types are valid
- Multiple choice questions have choices array
- True/false questions use correct format
- Media questions include media object

## Deployment (Heroku)

1. **Backend**

```bash
cd backend
heroku create thinknt-api
heroku addons:create heroku-postgresql:mini
heroku config:set OPENAI_API_KEY=your_key
git push heroku main
```

2. **Frontend**

Deploy to Vercel, Netlify, or similar. Update `VITE_API_URL` to point to your Heroku API URL.

## Development

### Running Tests (Backend)

```bash
cd backend
bundle exec rspec
```

### Building for Production

```bash
cd frontend
npm run build
```

## License

MIT

## Contributing

Pull requests welcome! Please ensure all tests pass before submitting.
