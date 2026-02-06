function AnswerReveal({ question, onClose }) {
  const renderCorrectChoice = () => {
    if (question.type === 'multiple_choice' && question.choices) {
      const letters = ['A', 'B', 'C', 'D', 'E', 'F'];
      const correctLetter = letters[question.correct_choice_index];
      const correctChoice = question.choices[question.correct_choice_index];
      return (
        <div className="mb-6">
          <div className="inline-block bg-green-500 px-6 py-3 rounded-lg text-2xl font-bold">
            {correctLetter}) {correctChoice}
          </div>
        </div>
      );
    }

    if (question.type === 'true_false' && question.choices) {
      const correctAnswer = question.choices[question.correct_choice_index];
      return (
        <div className="mb-6">
          <div className={`inline-block px-8 py-4 rounded-lg text-3xl font-bold ${
            correctAnswer === 'True' ? 'bg-green-500' : 'bg-red-500'
          }`}>
            {correctAnswer}
          </div>
        </div>
      );
    }

    return null;
  };

  return (
    <div 
      className="fixed inset-0 bg-black bg-opacity-90 backdrop-blur-sm flex items-center justify-center z-50 animate-fadeIn"
      onClick={onClose}
    >
      <div 
        className="bg-gradient-to-br from-yellow-400 to-orange-500 rounded-3xl p-12 max-w-4xl w-full mx-4 shadow-2xl transform animate-slideUp relative"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Close X Button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 w-10 h-10 bg-white bg-opacity-20 hover:bg-opacity-30 rounded-full flex items-center justify-center text-white text-2xl font-bold transition-all"
          aria-label="Close"
        >
          ×
        </button>

        {/* Header */}
        <div className="text-center mb-8">
          <h2 className="text-6xl font-black text-white mb-2 drop-shadow-lg">
            ANSWER
          </h2>
          <div className="h-2 w-32 bg-white mx-auto rounded-full"></div>
        </div>

        {/* Correct Choice (for MCQ and T/F) */}
        <div className="text-center mb-6">
          {renderCorrectChoice()}
        </div>

        {/* Main Answer (only for non-MCQ/T-F questions) */}
        {!['multiple_choice', 'true_false'].includes(question.type) && (
          <div className="bg-white bg-opacity-20 rounded-2xl p-8 mb-6">
            <p className="text-4xl font-bold text-white text-center leading-relaxed">
              {question.answer.display}
            </p>
          </div>
        )}

        {/* Explanation */}
        {question.answer.explanation && (
          <div className="bg-white bg-opacity-10 rounded-2xl p-6">
            <p className="text-xl text-white text-center italic">
              {question.answer.explanation}
            </p>
          </div>
        )}
      </div>

      <style jsx>{`
        @keyframes fadeIn {
          from {
            opacity: 0;
          }
          to {
            opacity: 1;
          }
        }

        @keyframes slideUp {
          from {
            transform: translateY(50px);
            opacity: 0;
          }
          to {
            transform: translateY(0);
            opacity: 1;
          }
        }

        .animate-fadeIn {
          animation: fadeIn 0.3s ease-out;
        }

        .animate-slideUp {
          animation: slideUp 0.4s ease-out;
        }
      `}</style>
    </div>
  );
}

export default AnswerReveal;
