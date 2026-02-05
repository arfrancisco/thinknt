require 'rails_helper'

RSpec.describe GenerateQuizJob, type: :job do
  let(:quiz) { create(:quiz, status: :generating) }
  let(:generation_params) do
    {
      'theme' => 'Test Theme',
      'participants' => [{ 'name' => 'Alice', 'age' => 30, 'country' => 'US' }],
      'countries' => ['US'],
      'rounds' => 2,
      'questions_per_round' => 3,
      'brainrot_level' => 'medium',
      'allowed_types' => ['text', 'multiple_choice']
    }
  end

  let(:valid_quiz_data) do
    JSON.parse(File.read(Rails.root.join('spec/fixtures/sample_quiz.json')))
  end

  describe '#perform' do
    before do
      allow(OpenaiQuizGenerator).to receive(:generate).and_return(valid_quiz_data)
    end

    it 'successfully generates quiz and updates record to ready' do
      described_class.new.perform(quiz.id, generation_params)
      
      quiz.reload
      expect(quiz.status).to eq('ready')
      expect(quiz.quiz_data).to be_present
      expect(quiz.quiz_data).to eq(valid_quiz_data)
    end

    it 'handles OpenAI API errors and sets status to failed' do
      allow(OpenaiQuizGenerator).to receive(:generate).and_raise(
        OpenaiQuizGenerator::GenerationError.new('API error')
      )
      
      described_class.new.perform(quiz.id, generation_params)
      
      quiz.reload
      expect(quiz.status).to eq('failed')
      expect(quiz.error_message).to include('API error')
    end

    it 'stores error message on failure' do
      error_message = 'OpenAI rate limit exceeded'
      allow(OpenaiQuizGenerator).to receive(:generate).and_raise(
        OpenaiQuizGenerator::GenerationError.new(error_message)
      )
      
      described_class.new.perform(quiz.id, generation_params)
      
      quiz.reload
      expect(quiz.error_message).to eq(error_message)
    end

    it 'symbolizes generation params keys' do
      expect(OpenaiQuizGenerator).to receive(:generate).with(
        hash_including(
          theme: 'Test Theme',
          participants: generation_params['participants']
        )
      )
      
      described_class.new.perform(quiz.id, generation_params)
    end
  end
end
