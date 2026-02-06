import { useState, useEffect } from 'react';

function QuizParamsForm({ 
  initialParams = {}, 
  onSubmit, 
  isSubmitting = false,
  submitLabel = 'Generate Quiz',
  error = ''
}) {
  const [theme, setTheme] = useState('');
  const [participants, setParticipants] = useState([{ name: '', age: '', country: '' }]);
  const [selectedTypes, setSelectedTypes] = useState(['text', 'audio', 'video', 'true_false', 'multiple_choice']);
  const [rounds, setRounds] = useState(3);
  const [questionsPerRound, setQuestionsPerRound] = useState(7);
  const [brainrotLevel, setBrainrotLevel] = useState('medium');

  // Update form values when initialParams changes (e.g., when loaded from backend)
  useEffect(() => {
    console.log('QuizParamsForm received initialParams:', initialParams);
    if (initialParams && Object.keys(initialParams).length > 0) {
      if (initialParams.theme !== undefined) {
        console.log('Setting theme:', initialParams.theme);
        setTheme(initialParams.theme);
      }
      if (initialParams.participants?.length > 0) {
        console.log('Setting participants:', initialParams.participants);
        setParticipants(initialParams.participants);
      }
      if (initialParams.allowed_types) {
        console.log('Setting allowed_types:', initialParams.allowed_types);
        setSelectedTypes(initialParams.allowed_types);
      }
      if (initialParams.rounds !== undefined) {
        console.log('Setting rounds:', initialParams.rounds);
        setRounds(initialParams.rounds);
      }
      if (initialParams.questions_per_round !== undefined) {
        console.log('Setting questions_per_round:', initialParams.questions_per_round);
        setQuestionsPerRound(initialParams.questions_per_round);
      }
      if (initialParams.brainrot_level) {
        console.log('Setting brainrot_level:', initialParams.brainrot_level);
        setBrainrotLevel(initialParams.brainrot_level);
      }
    }
  }, [JSON.stringify(initialParams)]); // Serialize to detect deep changes

  const questionTypes = ['text', 'audio', 'video', 'true_false', 'multiple_choice'];

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

  const toggleType = (type) => {
    if (selectedTypes.includes(type)) {
      setSelectedTypes(selectedTypes.filter(t => t !== type));
    } else {
      setSelectedTypes([...selectedTypes, type]);
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    
    const validParticipants = participants.filter(p => p.name && p.age && p.country);
    
    if (!theme || validParticipants.length === 0 || selectedTypes.length === 0) {
      return;
    }

    const params = {
      theme,
      participants: validParticipants.map(p => ({
        name: p.name,
        age: parseInt(p.age),
        country: p.country
      })),
      rounds,
      questions_per_round: questionsPerRound,
      brainrot_level: brainrotLevel,
      allowed_types: selectedTypes
    };

    onSubmit(params);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {error && (
        <div className="p-4 bg-red-50 border border-red-200 rounded-lg text-red-700">
          {error}
        </div>
      )}

      {/* Theme */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Theme *
        </label>
        <input
          type="text"
          value={theme}
          onChange={(e) => setTheme(e.target.value)}
          placeholder="e.g., 90s Pop Culture, Space Exploration"
          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent text-gray-900 bg-white"
          required
        />
      </div>

      {/* Participants */}
      <div>
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
              className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 text-gray-900 bg-white"
            />
            <input
              type="number"
              value={participant.age}
              onChange={(e) => updateParticipant(index, 'age', e.target.value)}
              placeholder="Age"
              min="10"
              max="99"
              className="w-20 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 text-gray-900 bg-white"
            />
            <input
              type="text"
              value={participant.country}
              onChange={(e) => updateParticipant(index, 'country', e.target.value)}
              placeholder="Country"
              className="w-32 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 text-gray-900 bg-white"
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

      {/* Question Types */}
      <div>
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
      <div className="grid grid-cols-2 gap-4">
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
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 text-gray-900 bg-white"
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
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 text-gray-900 bg-white"
          />
        </div>
      </div>

      {/* Brainrot Level */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Brainrot Level
        </label>
        <div className="flex gap-4">
          {['low', 'medium', 'high'].map((level) => (
            <label key={level} className="flex items-center cursor-pointer text-gray-900">
              <input
                type="radio"
                value={level}
                checked={brainrotLevel === level}
                onChange={(e) => setBrainrotLevel(e.target.value)}
                className="mr-2 w-4 h-4"
              />
              <span className="capitalize text-gray-900">{level}</span>
            </label>
          ))}
        </div>
      </div>

      {/* Submit Button */}
      <button
        type="submit"
        disabled={isSubmitting}
        className="w-full py-4 bg-gradient-to-r from-purple-600 to-blue-600 text-white font-bold rounded-lg hover:from-purple-700 hover:to-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
      >
        {isSubmitting ? (
          <span className="flex items-center justify-center">
            <svg className="animate-spin h-5 w-5 mr-3" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
            </svg>
            {submitLabel}...
          </span>
        ) : (
          submitLabel
        )}
      </button>
    </form>
  );
}

export default QuizParamsForm;
