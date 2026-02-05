function MultipleChoiceRenderer({ question }) {
  const { choices } = question;
  const letters = ['A', 'B', 'C', 'D', 'E', 'F'];

  return (
    <div className="w-full max-w-4xl mx-auto">
      <div className={`grid ${choices.length > 4 ? 'grid-cols-2' : 'grid-cols-2'} gap-6`}>
        {choices.map((choice, index) => (
          <div
            key={index}
            className="bg-purple-500 bg-opacity-20 border-4 border-purple-400 rounded-xl p-8 flex items-center gap-4 hover:bg-opacity-30 transition-all"
          >
            <div className="flex-shrink-0 w-12 h-12 bg-purple-500 rounded-full flex items-center justify-center">
              <span className="text-2xl font-bold">{letters[index]}</span>
            </div>
            <span className="text-2xl font-medium">{choice}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

export default MultipleChoiceRenderer;
