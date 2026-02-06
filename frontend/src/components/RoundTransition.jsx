function RoundTransition({ currentRound, nextRound, onContinue, totalRounds }) {
  return (
    <div className="fixed inset-0 bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900 flex items-center justify-center z-50 animate-fadeIn">
      <div className="text-center px-8">
        {/* Completion Message */}
        <div className="mb-12 animate-slideDown">
          <div className="text-6xl mb-4">🎉</div>
          <h2 className="text-7xl font-black text-white mb-4 drop-shadow-2xl">
            {currentRound.title}
          </h2>
          <p className="text-4xl text-yellow-300 font-bold">
            COMPLETE!
          </p>
        </div>

        {/* Divider */}
        <div className="my-12 flex items-center justify-center">
          <div className="h-1 w-32 bg-gradient-to-r from-transparent via-white to-transparent opacity-50"></div>
        </div>

        {/* Next Round Preview */}
        {nextRound && (
          <div className="mb-12 animate-slideUp">
            <p className="text-2xl text-gray-300 mb-4">Get Ready For...</p>
            <h3 className="text-6xl font-black text-transparent bg-clip-text bg-gradient-to-r from-green-400 to-blue-500 mb-3">
              {nextRound.title}
            </h3>
            <div className={`inline-block px-8 py-3 rounded-full text-2xl font-bold ${
              nextRound.difficulty === 'easy' ? 'bg-green-500' :
              nextRound.difficulty === 'medium' ? 'bg-yellow-500 text-black' :
              'bg-red-500'
            }`}>
              {nextRound.difficulty.toUpperCase()} DIFFICULTY
            </div>
          </div>
        )}

        {/* Round Progress Indicator */}
        <div className="mb-12 flex justify-center gap-3">
          {Array.from({ length: totalRounds }).map((_, idx) => (
            <div
              key={idx}
              className={`w-4 h-4 rounded-full transition-all ${
                idx < currentRound.round_index
                  ? 'bg-green-500 scale-110'
                  : idx === currentRound.round_index
                  ? 'bg-yellow-500 ring-4 ring-yellow-300 scale-125'
                  : 'bg-gray-600'
              }`}
            />
          ))}
        </div>

        {/* Continue Button */}
        <button
          onClick={onContinue}
          className="px-16 py-6 bg-gradient-to-r from-green-500 to-emerald-600 hover:from-green-600 hover:to-emerald-700 text-white font-black rounded-2xl text-3xl transition-all transform hover:scale-105 shadow-2xl"
        >
          Continue to Next Round →
        </button>

        {/* Keyboard Hint */}
        <p className="mt-6 text-gray-400 text-lg">
          Press → or click the button to continue
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
          animation: fadeIn 0.5s ease-out;
        }

        .animate-slideDown {
          animation: slideDown 0.6s ease-out;
        }

        .animate-slideUp {
          animation: slideUp 0.6s ease-out 0.3s both;
        }
      `}</style>
    </div>
  );
}

export default RoundTransition;
