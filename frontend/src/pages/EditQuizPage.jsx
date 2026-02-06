import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { getQuiz, updateQuiz, regenerateQuiz } from '../services/api';

function EditQuizPage() {
  const { quizId } = useParams();
  const navigate = useNavigate();
  const [quiz, setQuiz] = useState(null);
  const [quizJson, setQuizJson] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [regenerating, setRegenerating] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  useEffect(() => {
    loadQuiz();
  }, [quizId]);

  const loadQuiz = async () => {
    try {
      const data = await getQuiz(quizId);
      if (data.status === 'ready') {
        setQuiz(data.quiz);
        setQuizJson(JSON.stringify(data.quiz, null, 2));
      } else {
        setError('Quiz is not ready for editing');
      }
    } catch (err) {
      setError('Failed to load quiz');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    setError('');
    setSuccess('');
    setSaving(true);

    try {
      // Validate JSON
      const parsedQuiz = JSON.parse(quizJson);
      
      // Save to backend
      const response = await updateQuiz(quizId, parsedQuiz);
      setQuiz(response.quiz);
      setSuccess('Quiz saved successfully!');
      
      // Auto-hide success message after 3 seconds
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      if (err instanceof SyntaxError) {
        setError(`Invalid JSON: ${err.message}`);
      } else if (err.response?.data?.validation_errors) {
        setError(`Validation errors:\n${err.response.data.validation_errors.join('\n')}`);
      } else {
        setError('Failed to save quiz. Please check your JSON format.');
      }
    } finally {
      setSaving(false);
    }
  };

  const handleFormat = () => {
    try {
      const parsed = JSON.parse(quizJson);
      setQuizJson(JSON.stringify(parsed, null, 2));
      setError('');
    } catch (err) {
      setError(`Cannot format invalid JSON: ${err.message}`);
    }
  };

  const handleReset = () => {
    if (quiz) {
      setQuizJson(JSON.stringify(quiz, null, 2));
      setError('');
      setSuccess('Reset to saved version');
      setTimeout(() => setSuccess(''), 3000);
    }
  };

  const handleRegenerate = async () => {
    if (!window.confirm('This will regenerate the entire quiz with the same parameters. Your current edits will be lost. Continue?')) {
      return;
    }

    setRegenerating(true);
    setError('');
    setSuccess('');

    try {
      await regenerateQuiz(quizId);
      
      // Poll for completion
      const pollInterval = setInterval(async () => {
        try {
          const data = await getQuiz(quizId);
          if (data.status === 'ready') {
            clearInterval(pollInterval);
            setQuiz(data.quiz);
            setQuizJson(JSON.stringify(data.quiz, null, 2));
            setRegenerating(false);
            setSuccess('Quiz regenerated successfully!');
            setTimeout(() => setSuccess(''), 3000);
          } else if (data.status === 'failed') {
            clearInterval(pollInterval);
            setRegenerating(false);
            setError(`Regeneration failed: ${data.error_message}`);
          }
        } catch (err) {
          clearInterval(pollInterval);
          setRegenerating(false);
          setError('Failed to check regeneration status');
        }
      }, 2000);
      
      // Timeout after 2 minutes
      setTimeout(() => {
        clearInterval(pollInterval);
        if (regenerating) {
          setRegenerating(false);
          setError('Regeneration timed out');
        }
      }, 120000);
    } catch (err) {
      setRegenerating(false);
      setError('Failed to start regeneration');
    }
  };

  const goToPresenter = () => {
    navigate(`/presenter/${quizId}`);
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-white text-2xl">Loading quiz...</div>
      </div>
    );
  }

  if (!quiz) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-red-400 text-2xl">{error || 'Quiz not found'}</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-purple-900 to-blue-900 text-white p-8">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-6 flex justify-between items-center">
          <div>
            <h1 className="text-4xl font-bold mb-2">Edit Quiz JSON</h1>
            <p className="text-gray-300">Make changes to your quiz structure and content</p>
          </div>
          <button
            onClick={goToPresenter}
            className="px-6 py-3 bg-purple-600 hover:bg-purple-700 text-white font-bold rounded-lg transition-colors"
          >
            Go to Presenter →
          </button>
        </div>

        {/* Success/Error Messages */}
        {success && (
          <div className="mb-4 p-4 bg-green-600 bg-opacity-20 border border-green-500 rounded-lg">
            <p className="text-green-300">{success}</p>
          </div>
        )}
        
        {error && (
          <div className="mb-4 p-4 bg-red-600 bg-opacity-20 border border-red-500 rounded-lg">
            <p className="text-red-300 whitespace-pre-wrap">{error}</p>
          </div>
        )}

        {/* Action Buttons */}
        <div className="mb-4 flex gap-3 justify-between">
          <div className="flex gap-3">
            <button
              onClick={handleSave}
              disabled={saving || regenerating}
              className="px-6 py-3 bg-green-600 hover:bg-green-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white font-bold rounded-lg transition-colors"
            >
              {saving ? 'Saving...' : 'Save Changes'}
            </button>
            <button
              onClick={handleFormat}
              disabled={regenerating}
              className="px-6 py-3 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-600 text-white font-bold rounded-lg transition-colors"
            >
              Format JSON
            </button>
            <button
              onClick={handleReset}
              disabled={regenerating}
              className="px-6 py-3 bg-yellow-600 hover:bg-yellow-700 disabled:bg-gray-600 text-white font-bold rounded-lg transition-colors"
            >
              Reset to Saved
            </button>
          </div>
          
          <button
            onClick={handleRegenerate}
            disabled={saving || regenerating}
            className="px-6 py-3 bg-orange-600 hover:bg-orange-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white font-bold rounded-lg transition-colors"
          >
            {regenerating ? (
              <span className="flex items-center">
                <svg className="animate-spin h-5 w-5 mr-2" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
                Regenerating...
              </span>
            ) : (
              '🔄 Regenerate Entire Quiz'
            )}
          </button>
        </div>

        {/* JSON Editor */}
        <div className="bg-gray-800 rounded-lg p-4 shadow-2xl">
          <textarea
            value={quizJson}
            onChange={(e) => setQuizJson(e.target.value)}
            className="w-full h-[600px] bg-gray-900 text-green-400 font-mono text-sm p-4 rounded border border-gray-700 focus:border-blue-500 focus:outline-none resize-none"
            spellCheck={false}
          />
        </div>

        {/* Helper Info */}
        <div className="mt-6 p-4 bg-blue-900 bg-opacity-30 border border-blue-700 rounded-lg">
          <h3 className="font-bold text-lg mb-2">💡 Tips:</h3>
          <ul className="list-disc list-inside space-y-1 text-gray-300">
            <li>Use "Format JSON" to auto-format your changes</li>
            <li>The schema is validated on save - invalid JSON will be rejected</li>
            <li>You can add, remove, or modify questions directly</li>
            <li>Change video IDs, text, difficulty levels, and more</li>
            <li>Use "Reset to Saved" if you want to start over</li>
          </ul>
        </div>
      </div>
    </div>
  );
}

export default EditQuizPage;
