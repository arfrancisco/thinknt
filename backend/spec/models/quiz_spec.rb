require 'rails_helper'

RSpec.describe Quiz, type: :model do
  describe 'validations' do
    it 'validates presence of theme' do
      quiz = Quiz.new(status: :generating)
      expect(quiz).not_to be_valid
      expect(quiz.errors[:theme]).to include("can't be blank")
    end

    it 'validates presence of status' do
      quiz = Quiz.new(theme: "Test Theme", status: nil)
      expect(quiz).not_to be_valid
    end
  end

  describe 'status enum' do
    it 'has generating status' do
      quiz = Quiz.create!(theme: "Test", status: :generating)
      expect(quiz.generating?).to be true
    end

    it 'has ready status' do
      quiz = Quiz.create!(theme: "Test", status: :ready)
      expect(quiz.ready?).to be true
    end

    it 'has failed status' do
      quiz = Quiz.create!(theme: "Test", status: :failed)
      expect(quiz.failed?).to be true
    end
  end

  describe '#validate_quiz_schema' do
    let(:quiz) { create(:quiz, :ready) }

    it 'validates correct schema' do
      expect(quiz.validate_quiz_schema).to be true
    end

    it 'returns false for missing required fields' do
      quiz.quiz_data = { "title" => "Test" }
      expect(quiz.validate_quiz_schema).to be false
    end

    it 'returns false for invalid question types' do
      quiz.quiz_data["rounds"][0]["questions"][0]["type"] = "invalid_type"
      expect(quiz.validate_quiz_schema).to be false
    end

    it 'returns false when quiz_data is nil' do
      quiz.quiz_data = nil
      expect(quiz.validate_quiz_schema).to be false
    end
  end

  describe '#quiz_schema_errors' do
    let(:quiz) { create(:quiz, :ready) }

    it 'returns empty array for valid quiz' do
      expect(quiz.quiz_schema_errors).to be_empty
    end

    it 'returns error messages for invalid quiz' do
      quiz.quiz_data = { "title" => "Test" }
      errors = quiz.quiz_schema_errors
      expect(errors).not_to be_empty
      expect(errors.first).to include("required")
    end
  end

  describe '.compute_audience_stats' do
    it 'calculates min, max, and avg age' do
      participants = [
        { 'name' => 'Alice', 'age' => 25, 'country' => 'US' },
        { 'name' => 'Bob', 'age' => 35, 'country' => 'UK' },
        { 'name' => 'Charlie', 'age' => 30, 'country' => 'CA' }
      ]
      
      stats = Quiz.compute_audience_stats(participants)
      
      expect(stats[:min]).to eq(25)
      expect(stats[:max]).to eq(35)
      expect(stats[:avg]).to eq(30.0)
    end

    it 'handles single participant' do
      participants = [{ 'name' => 'Alice', 'age' => 25, 'country' => 'US' }]
      
      stats = Quiz.compute_audience_stats(participants)
      
      expect(stats[:min]).to eq(25)
      expect(stats[:max]).to eq(25)
      expect(stats[:avg]).to eq(25.0)
    end

    it 'returns empty hash for empty participants' do
      stats = Quiz.compute_audience_stats([])
      expect(stats).to eq({})
    end

    it 'handles symbolized keys' do
      participants = [
        { name: 'Alice', age: 25, country: 'US' },
        { name: 'Bob', age: 35, country: 'UK' }
      ]
      
      stats = Quiz.compute_audience_stats(participants)
      
      expect(stats[:min]).to eq(25)
      expect(stats[:max]).to eq(35)
      expect(stats[:avg]).to eq(30.0)
    end
  end

  describe '#retry_generation' do
    let(:generation_params) do
      {
        'theme' => 'Movies',
        'rounds' => 2,
        'questions_per_round' => 5
      }
    end
    let(:quiz) { create(:quiz, :failed, generation_params: generation_params) }

    it 'resets quiz status and enqueues job' do
      expect {
        quiz.retry_generation
      }.to have_enqueued_job(GenerateQuizJob).with(quiz.id, generation_params)
      
      quiz.reload
      expect(quiz.generating?).to be true
      expect(quiz.error_message).to be_nil
      expect(quiz.quiz_data).to be_nil
    end
  end
end
