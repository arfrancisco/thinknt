function TrueFalseRenderer({ question }) {
  return (
    <div className="grid grid-cols-2 gap-8 w-full max-w-2xl mx-auto">
      <div className="bg-green-500 bg-opacity-20 border-4 border-green-500 rounded-xl p-12 flex items-center justify-center">
        <span className="text-6xl font-bold text-green-400">TRUE</span>
      </div>
      <div className="bg-red-500 bg-opacity-20 border-4 border-red-500 rounded-xl p-12 flex items-center justify-center">
        <span className="text-6xl font-bold text-red-400">FALSE</span>
      </div>
    </div>
  );
}

export default TrueFalseRenderer;
