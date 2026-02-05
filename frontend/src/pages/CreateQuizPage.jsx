import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { createQuiz, getQuiz } from '../services/api';

function CreateQuizPage() {
  const navigate = useNavigate();
  const [theme, setTheme] = useState('');
  const [participants, setParticipants] = useState([{ name: '', age: '', country: '' }]);
  const [selectedCountries, setSelectedCountries] = useState(['Philippines', 'UK', 'Italy']);
  const [selectedTypes, setSelectedTypes] = useState(['text', 'audio', 'video', 'image', 'true_false', 'multiple_choice']);
  const [rounds, setRounds] = useState(3);
  const [questionsPerRound, setQuestionsPerRound] = useState(7);
  const [brainrotLevel, setBrainrotLevel] = useState('medium');
  const [isGenerating, setIsGenerating] = useState(false);
  const [error, setError] = useState('');

  const availableCountries = ['Philippines', 'UK', 'Italy', 'US', 'Canada', 'Australia', 'Japan', 'Germany', 'France', 'Spain'];
  const questionTypes = ['text', 'audio', 'video', 'image', 'true_false', 'multiple_choice'];

  const addParticipant = () => {
    setParticipants([...participants, { name: '', age: '', country: '' }]);
  };

  const removeParticipant = (index) => {
    if (participants.length > 1) {
      setParticipants(participants.filter((_, i) => i !== index));
    }
  };

  const updateParticipant = (index, field, value) => {
    const updated = [...participants];
    updated[index][field] = value;
    setParticipants(updated);
  };

  const toggleCountry = (country) => {
    if (selectedCountries.includes(country)) {
      setSelectedCountries(selectedCountries.filter(c => c !== country));
    } else {
      setSelectedCountries([...selectedCountries, country]);
    }
  };

  const toggleType = (type) => {
    if (selectedTypes.includes(type)) {
      setSelectedTypes(selectedTypes.filter(t => t !== type));
    } else {
      setSelectedTypes([...selectedTypes, type]);
    }
  };

  const pollQuizStatus = async (quizId) => {
    const maxAttempts = 60; // 2 minutes max
    let attempts = 0;

    const poll = setInterval(async () => {
      attempts++;
      try {
        const data = await getQuiz(quizId);
        
        if (data.status === 'ready') {
          clearInterval(poll);
          navigate(`/presenter/${quizId}`);
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

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setIsGenerating(true);

    const validParticipants = participants.filter(p => p.name && p.age && p.country);
    
    if (!theme || validParticipants.length === 0 || selectedCountries.length === 0 || selectedTypes.length === 0) {
      setError('Please fill in all required fields');
      setIsGenerating(false);
      return;
    }

    try {
      const payload = {
        theme,
        participants: validParticipants.map(p => ({
          name: p.name,
          age: parseInt(p.age),
          country: p.country
        })),
        countries: selectedCountries,
        rounds,
        questions_per_round: questionsPerRound,
        brainrot_level: brainrotLevel,
        allowed_types: selectedTypes
      };

      const data = await createQuiz(payload);
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

        <form onSubmit={handleSubmit} className="bg-white rounded-lg shadow-lg p-8">
          {error && (
            <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700">
              {error}
            </div>
          )}

          {/* Theme */}
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Theme *
            </label>
            <input
              type="text"
              value={theme}
              onChange={(e) => setTheme(e.target.value)}
              placeholder="e.g., 90s Pop Culture, Space Exploration"
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
              required
            />
          </div>

          {/* Participants */}
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Participants *
            </label>
            {participants.map((participant, index) => (
              <div key={index} className="flex gap-2 mb-2">
                <input
                  type="text"
                  value={participant.name}
                  onChange={(e) => updateParticipant(index, 'name', e.target.value)}
                  placeholder="Name"
                  className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
                />
                <input
                  type="number"
                  value={participant.age}
                  onChange={(e) => updateParticipant(index, 'age', e.target.value)}
                  placeholder="Age"
                  min="10"
                  max="99"
                  className="w-20 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
                />
                <input
                  type="text"
                  value={participant.country}
                  onChange={(e) => updateParticipant(index, 'country', e.target.value)}
                  placeholder="Country"
                  className="w-32 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
                />
                {participants.length > 1 && (
                  <button
                    type="button"
                    onClick={() => removeParticipant(index)}
                    className="px-4 py-2 bg-red-100 text-red-700 rounded-lg hover:bg-red-200"
                  >
                    Remove
                  </button>
                )}
              </div>
            ))}
            <button
              type="button"
              onClick={addParticipant}
              className="mt-2 px-4 py-2 bg-purple-100 text-purple-700 rounded-lg hover:bg-purple-200"
            >
              + Add Participant
            </button>
          </div>

          {/* Countries */}
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Countries *
            </label>
            <div className="flex flex-wrap gap-2">
              {availableCountries.map((country) => (
                <button
                  key={country}
                  type="button"
                  onClick={() => toggleCountry(country)}
                  className={`px-4 py-2 rounded-lg border ${
                    selectedCountries.includes(country)
                      ? 'bg-purple-500 text-white border-purple-500'
                      : 'bg-white text-gray-700 border-gray-300 hover:border-purple-300'
                  }`}
                >
                  {country}
                </button>
              ))}
            </div>
          </div>

          {/* Question Types */}
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Question Types *
            </label>
            <div className="flex flex-wrap gap-2">
              {questionTypes.map((type) => (
                <button
                  key={type}
                  type="button"
                  onClick={() => toggleType(type)}
                  className={`px-4 py-2 rounded-lg border ${
                    selectedTypes.includes(type)
                      ? 'bg-blue-500 text-white border-blue-500'
                      : 'bg-white text-gray-700 border-gray-300 hover:border-blue-300'
                  }`}
                >
                  {type.replace('_', ' ').toUpperCase()}
                </button>
              ))}
            </div>
          </div>

          {/* Rounds and Questions */}
          <div className="grid grid-cols-2 gap-4 mb-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Rounds
              </label>
              <input
                type="number"
                value={rounds}
                onChange={(e) => setRounds(parseInt(e.target.value))}
                min="1"
                max="5"
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Questions per Round
              </label>
              <input
                type="number"
                value={questionsPerRound}
                onChange={(e) => setQuestionsPerRound(parseInt(e.target.value))}
                min="1"
                max="10"
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
              />
            </div>
          </div>

          {/* Brainrot Level */}
          <div className="mb-8">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Brainrot Level
            </label>
            <div className="flex gap-4">
              {['low', 'medium', 'high'].map((level) => (
                <label key={level} className="flex items-center cursor-pointer">
                  <input
                    type="radio"
                    value={level}
                    checked={brainrotLevel === level}
                    onChange={(e) => setBrainrotLevel(e.target.value)}
                    className="mr-2"
                  />
                  <span className="capitalize">{level}</span>
                </label>
              ))}
            </div>
          </div>

          {/* Submit Button */}
          <button
            type="submit"
            disabled={isGenerating}
            className="w-full py-4 bg-gradient-to-r from-purple-600 to-blue-600 text-white font-bold rounded-lg hover:from-purple-700 hover:to-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
          >
            {isGenerating ? (
              <span className="flex items-center justify-center">
                <svg className="animate-spin h-5 w-5 mr-3" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
                Generating Quiz...
              </span>
            ) : (
              'Generate Quiz'
            )}
          </button>
        </form>
      </div>
    </div>
  );
}

export default CreateQuizPage;
