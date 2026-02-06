import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { createQuiz, getQuiz } from '../services/api';
import QuizParamsForm from '../components/QuizParamsForm';

function CreateQuizPage() {
  const navigate = useNavigate();
  const [isGenerating, setIsGenerating] = useState(false);
  const [quizReady, setQuizReady] = useState(false);
  const [generatedQuizId, setGeneratedQuizId] = useState(null);
  const [error, setError] = useState('');

  const pollQuizStatus = async (quizId) => {
    const maxAttempts = 60; // 2 minutes max
    let attempts = 0;

    const poll = setInterval(async () => {
      attempts++;
      try {
        const data = await getQuiz(quizId);
        
        if (data.status === 'ready') {
          clearInterval(poll);
          setIsGenerating(false);
          setQuizReady(true);
          setGeneratedQuizId(quizId);
        } else if (data.status === 'failed') {
          clearInterval(poll);
          setIsGenerating(false);
          setError(`Quiz generation failed: ${data.error_message}`);
        } else if (attempts >= maxAttempts) {
          clearInterval(poll);
          setIsGenerating(false);
          setError('Quiz generation timed out. Please try again.');
        }
      } catch (err) {
        clearInterval(poll);
        setIsGenerating(false);
        setError('Error checking quiz status. Please try again.');
      }
    }, 2000);
  };

  const handleSubmit = async (params) => {
    setError('');
    setIsGenerating(true);

    try {
      const data = await createQuiz(params);
      pollQuizStatus(data.quiz_id);
    } catch (err) {
      setIsGenerating(false);
      setError(err.response?.data?.errors?.join(', ') || 'Failed to create quiz. Please try again.');
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 to-blue-50 py-12 px-4">
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-8">
          <h1 className="text-5xl font-bold text-purple-900 mb-2">Thinkn't</h1>
          <p className="text-gray-600">AI-powered quiz night generator</p>
        </div>

        <div className="bg-white rounded-lg shadow-lg p-8">
          {!quizReady ? (
            <QuizParamsForm
              onSubmit={handleSubmit}
              isSubmitting={isGenerating}
              error={error}
            />
          ) : (
            <div className="space-y-3">
              <div className="text-center mb-4">
                <div className="inline-flex items-center px-4 py-2 bg-green-100 text-green-800 rounded-lg">
                  <svg className="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                  </svg>
                  Quiz Generated Successfully!
                </div>
              </div>
              <button
                onClick={() => navigate(`/presenter/${generatedQuizId}`)}
                className="w-full py-4 bg-gradient-to-r from-green-600 to-emerald-600 text-white font-bold rounded-lg hover:from-green-700 hover:to-emerald-700 transition-all shadow-lg"
              >
                Start Presenter Mode →
              </button>
              <button
                onClick={() => navigate(`/edit/${generatedQuizId}`)}
                className="w-full py-4 bg-gradient-to-r from-blue-600 to-indigo-600 text-white font-bold rounded-lg hover:from-blue-700 hover:to-indigo-700 transition-all"
              >
                Edit Quiz JSON
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default CreateQuizPage;
