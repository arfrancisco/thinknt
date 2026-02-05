import TextRenderer from './renderers/TextRenderer';
import AudioRenderer from './renderers/AudioRenderer';
import VideoRenderer from './renderers/VideoRenderer';
import ImageRenderer from './renderers/ImageRenderer';
import TrueFalseRenderer from './renderers/TrueFalseRenderer';
import MultipleChoiceRenderer from './renderers/MultipleChoiceRenderer';

function QuestionFrame({ question }) {
  const renderContent = () => {
    switch (question.type) {
      case 'text':
        return <TextRenderer question={question} />;
      case 'audio':
        return <AudioRenderer question={question} />;
      case 'video':
        return <VideoRenderer question={question} />;
      case 'image':
        return <ImageRenderer question={question} />;
      case 'true_false':
        return <TrueFalseRenderer question={question} />;
      case 'multiple_choice':
        return <MultipleChoiceRenderer question={question} />;
      default:
        return <div className="text-red-400">Unknown question type: {question.type}</div>;
    }
  };

  return (
    <div className="max-w-5xl mx-auto">
      {/* Prompt */}
      <div className="mb-8">
        <h3 className="text-4xl font-bold mb-4">{question.prompt}</h3>
        {question.instructions && (
          <p className="text-xl text-gray-300 italic">{question.instructions}</p>
        )}
      </div>

      {/* Content Panel */}
      <div className="bg-white bg-opacity-10 backdrop-blur-sm rounded-2xl p-8 min-h-[400px] flex items-center justify-center">
        {renderContent()}
      </div>

      {/* Difficulty Badge */}
      <div className="mt-4 flex justify-end">
        <span className={`px-4 py-2 rounded-full font-medium ${
          question.difficulty === 'easy' ? 'bg-green-500' :
          question.difficulty === 'medium' ? 'bg-yellow-500' :
          'bg-red-500'
        }`}>
          {question.difficulty.toUpperCase()}
        </span>
      </div>
    </div>
  );
}

export default QuestionFrame;
