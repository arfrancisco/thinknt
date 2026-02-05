import { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { getQuiz } from '../services/api';
import QuestionFrame from '../components/QuestionFrame';
import AnswerReveal from '../components/AnswerReveal';

function PresenterPage() {
  const { quizId } = useParams();
  const [quiz, setQuiz] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [currentRoundIndex, setCurrentRoundIndex] = useState(0);
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [showAnswer, setShowAnswer] = useState(false);

  useEffect(() => {
    loadQuiz();
  }, [quizId]);

  useEffect(() => {
    const handleKeyPress = (e) => {
      if (e.code === 'Space') {
        e.preventDefault();
        setShowAnswer(!showAnswer);
      } else if (e.code === 'ArrowRight') {
        e.preventDefault();
        handleNext();
      }
    };

    window.addEventListener('keydown', handleKeyPress);
    return () => window.removeEventListener('keydown', handleKeyPress);
  }, [showAnswer, currentRoundIndex, currentQuestionIndex]);

  const loadQuiz = async () => {
    try {
      const data = await getQuiz(quizId);
      if (data.status === 'ready') {
        setQuiz(data.quiz);
      } else if (data.status === 'failed') {
        setError(`Quiz generation failed: ${data.error_message}`);
      } else {
        setError('Quiz is still generating...');
      }
    } catch (err) {
      setError('Failed to load quiz. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleNext = () => {
    if (!quiz) return;

    const currentRound = quiz.rounds[currentRoundIndex];
    
    if (showAnswer) {
      setShowAnswer(false);
      return;
    }

    if (currentQuestionIndex < currentRound.questions.length - 1) {
      setCurrentQuestionIndex(currentQuestionIndex + 1);
    } else if (currentRoundIndex < quiz.rounds.length - 1) {
      setCurrentRoundIndex(currentRoundIndex + 1);
      setCurrentQuestionIndex(0);
    }
  };

  const handleReveal = () => {
    setShowAnswer(!showAnswer);
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-white text-2xl">Loading quiz...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-red-400 text-2xl">{error}</div>
      </div>
    );
  }

  if (!quiz) {
    return null;
  }

  const currentRound = quiz.rounds[currentRoundIndex];
  const currentQuestion = currentRound.questions[currentQuestionIndex];
  const totalQuestions = quiz.rounds.reduce((sum, round) => sum + round.questions.length, 0);
  const currentQuestionNumber = quiz.rounds
    .slice(0, currentRoundIndex)
    .reduce((sum, round) => sum + round.questions.length, 0) + currentQuestionIndex + 1;

  const isLastQuestion = currentRoundIndex === quiz.rounds.length - 1 && 
                         currentQuestionIndex === currentRound.questions.length - 1;

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-purple-900 to-blue-900 text-white">
      {/* Header */}
      <div className="bg-black bg-opacity-50 px-8 py-4 flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold">
            {currentRound.title} - {currentRound.difficulty.toUpperCase()}
          </h2>
        </div>
        <div className="text-xl font-medium">
          Question {currentQuestionNumber} / {totalQuestions}
        </div>
      </div>

      {/* Main Content */}
      <div className="container mx-auto px-8 py-12">
        <QuestionFrame question={currentQuestion} />
      </div>

      {/* Controls */}
      <div className="fixed bottom-0 left-0 right-0 bg-black bg-opacity-50 px-8 py-6 flex justify-between items-center">
        <button
          onClick={handleReveal}
          className="px-8 py-4 bg-yellow-500 hover:bg-yellow-600 text-black font-bold rounded-lg text-xl transition-colors"
        >
          {showAnswer ? 'Hide Answer' : 'Reveal Answer'}
        </button>

        {!isLastQuestion && (
          <button
            onClick={handleNext}
            className="px-8 py-4 bg-green-500 hover:bg-green-600 text-white font-bold rounded-lg text-xl transition-colors"
          >
            Next Question →
          </button>
        )}

        {isLastQuestion && showAnswer && (
          <div className="px-8 py-4 bg-purple-500 text-white font-bold rounded-lg text-xl">
            Quiz Complete!
          </div>
        )}
      </div>

      {/* Answer Reveal Overlay */}
      {showAnswer && <AnswerReveal question={currentQuestion} onClose={() => setShowAnswer(false)} />}

      {/* Keyboard Hints */}
      <div className="fixed top-4 right-4 bg-black bg-opacity-70 px-4 py-2 rounded text-sm">
        <div>Space: Reveal Answer</div>
        <div>→ Arrow: Next</div>
      </div>
    </div>
  );
}

export default PresenterPage;
