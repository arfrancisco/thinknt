import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import CreateQuizPage from './pages/CreateQuizPage'
import PresenterPage from './pages/PresenterPage'

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<CreateQuizPage />} />
        <Route path="/presenter/:quizId" element={<PresenterPage />} />
      </Routes>
    </Router>
  )
}

export default App
