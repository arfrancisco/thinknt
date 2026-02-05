require 'rails_helper'

RSpec.describe OpenaiQuizGenerator do
  let(:params) do
    {
      theme: "Space Exploration",
      participants: [{ name: "Alice", age: 28, country: "US" }],
      countries: ["US", "UK"],
      rounds: 3,
      questions_per_round: 5,
      brainrot_level: "medium",
      allowed_types: ["text", "multiple_choice"]
    }
  end

  let(:valid_quiz_json) do
    File.read(Rails.root.join('spec/fixtures/sample_quiz.json'))
  end

  before do
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(
        status: 200,
        body: { 
          choices: [
            { 
              message: { 
                content: valid_quiz_json 
              } 
            }
          ] 
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  describe '.generate' do
    it 'generates a valid quiz' do
      result = described_class.generate(params)
      
      expect(result).to be_a(Hash)
      expect(result).to include("id", "title", "rounds")
    end

    it 'validates quiz against schema' do
      result = described_class.generate(params)
      
      schema_path = Rails.root.join('config', 'quiz_schema.json')
      schema = JSON.parse(File.read(schema_path))
      errors = JSON::Validator.fully_validate(schema, result)
      
      expect(errors).to be_empty
    end

    it 'includes audience stats in generation' do
      allow(Quiz).to receive(:compute_audience_stats).and_call_original
      
      described_class.generate(params)
      
      expect(Quiz).to have_received(:compute_audience_stats).with(params[:participants])
    end

    it 'raises error when OpenAI fails' do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(status: 500, body: "Internal Server Error")
      
      expect {
        described_class.generate(params)
      }.to raise_error(OpenaiQuizGenerator::GenerationError, /OpenAI API error/)
    end

    it 'attempts repair when schema validation fails' do
      invalid_json = '{"title": "Test"}'
      
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(
          { status: 200, body: { choices: [{ message: { content: invalid_json } }] }.to_json },
          { status: 200, body: { choices: [{ message: { content: valid_quiz_json } }] }.to_json }
        )
      
      result = described_class.generate(params)
      
      expect(result).to be_a(Hash)
      expect(result).to include("id", "title", "rounds")
    end

    it 'raises error after failed repair attempt' do
      invalid_json = '{"title": "Test"}'
      
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(
          status: 200,
          body: { choices: [{ message: { content: invalid_json } }] }.to_json
        )
      
      expect {
        described_class.generate(params)
      }.to raise_error(OpenaiQuizGenerator::GenerationError, /Failed to generate valid quiz/)
    end
  end
end
