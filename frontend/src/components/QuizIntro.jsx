function QuizIntro({ quiz, onStart }) {
  return (
    <div className="fixed inset-0 bg-gradient-to-br from-purple-900 via-indigo-900 to-blue-900 flex items-center justify-center z-50 animate-fadeIn">
      <div className="text-center px-8 max-w-4xl">
        {/* Main Title */}
        <div className="mb-8 animate-slideDown">
          <div className="text-6xl mb-6">🎯</div>
          <h1 className="text-7xl font-black text-transparent bg-clip-text bg-gradient-to-r from-yellow-400 via-pink-500 to-purple-600 mb-6 drop-shadow-2xl">
            {quiz.title}
          </h1>
          {quiz.subtitle && (
            <p className="text-2xl text-gray-300 mb-8">
              {quiz.subtitle}
            </p>
          )}
        </div>

        {/* Quiz Info */}
        <div className="mb-12 space-y-4 animate-slideUp">
          <div className="inline-block bg-white bg-opacity-10 backdrop-blur px-8 py-4 rounded-2xl">
            <p className="text-3xl font-bold text-white">
              {quiz.rounds.length} Rounds • {quiz.rounds.reduce((sum, r) => sum + r.questions.length, 0)} Questions
            </p>
          </div>
          
          {/* Round Preview */}
          <div className="flex justify-center gap-4 mt-6">
            {quiz.rounds.map((round, idx) => (
              <div
                key={idx}
                className="bg-white bg-opacity-20 backdrop-blur px-6 py-3 rounded-xl"
              >
                <p className="text-sm text-gray-300 mb-1">Round {idx + 1}</p>
                <p className={`text-lg font-bold ${
                  round.difficulty === 'easy' ? 'text-green-400' :
                  round.difficulty === 'medium' ? 'text-yellow-400' :
                  'text-red-400'
                }`}>
                  {round.difficulty.toUpperCase()}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* Start Button */}
        <button
          onClick={onStart}
          className="px-20 py-8 bg-gradient-to-r from-green-500 to-emerald-600 hover:from-green-600 hover:to-emerald-700 text-white font-black rounded-2xl text-4xl transition-all transform hover:scale-105 shadow-2xl animate-pulse"
        >
          Let's Begin! 🚀
        </button>

        {/* Keyboard Hint */}
        <p className="mt-8 text-gray-400 text-lg animate-fadeIn">
          Press → to start
        </p>
      </div>

      <style jsx>{`
        @keyframes fadeIn {
          from { opacity: 0; }
          to { opacity: 1; }
        }

        @keyframes slideDown {
          from {
            transform: translateY(-50px);
            opacity: 0;
          }
          to {
            transform: translateY(0);
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
          animation: fadeIn 0.8s ease-out;
        }

        .animate-slideDown {
          animation: slideDown 0.6s ease-out;
        }

        .animate-slideUp {
          animation: slideUp 0.6s ease-out 0.4s both;
        }
      `}</style>
    </div>
  );
}

export default QuizIntro;
