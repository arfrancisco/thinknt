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
    # Quiz without video/audio to avoid YouTube enrichment
    {
      "id" => "qz_test_001",
      "title" => "Test Quiz",
      "subtitle" => "Simple test",
      "locale" => {
        "primary" => "en",
        "countries" => ["US"]
      },
      "difficulty_curve" => "progressive",
      "rounds" => [{
        "round_index" => 1,
        "title" => "Round 1",
        "difficulty" => "easy",
        "questions" => [{
          "id" => "q_001",
          "type" => "text",
          "difficulty" => "easy",
          "prompt" => "Test question?",
          "answer" => { "display" => "Test answer" }
        }]
      }]
    }.to_json
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
  
  describe 'YouTube enrichment' do
    let(:params_with_video) do
      {
        theme: "Famous Songs",
        participants: [{ name: "Alice", age: 28, country: "US" }],
        countries: ["US"],
        rounds: 1,
        questions_per_round: 2,
        brainrot_level: "medium",
        allowed_types: ["audio", "video"]
      }
    end
    
    let(:quiz_with_videos) do
      {
        "id" => "test_quiz",
        "title" => "Music Quiz",
        "subtitle" => "Test subtitle",
        "locale" => {
          "primary" => "en",
          "countries" => ["US"]
        },
        "audience" => {
          "participants" => [{ "name" => "Alice", "age" => 28, "country" => "US" }],
          "age_stats" => { "min" => 28, "max" => 28, "avg" => 28.0 }
        },
        "difficulty_curve" => "progressive",
        "rounds" => [
          {
            "round_index" => 1,
            "title" => "Round 1",
            "difficulty" => "easy",
            "questions" => [
              {
                "id" => "q1",
                "type" => "audio",
                "difficulty" => "easy",
                "prompt" => "Name this song",
                "media" => {
                  "provider" => "youtube",
                  "mode" => "audio",
                  "video_id" => "dQw4w9WgXcQ",
                  "start_sec" => 10,
                  "end_sec" => 25
                },
                "answer" => { "display" => "Artist - Song Title" }
              },
              {
                "id" => "q2",
                "type" => "video",
                "difficulty" => "easy",
                "prompt" => "Name this video",
                "media" => {
                  "provider" => "youtube",
                  "mode" => "video",
                  "video_id" => "dQw4w9WgXcQ",
                  "start_sec" => 10,
                  "end_sec" => 25
                },
                "answer" => { "display" => "Another Song" }
              }
            ]
          }
        ]
      }.to_json
    end
    
    before do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(
          status: 200,
          body: { 
            choices: [{ message: { content: quiz_with_videos } }] 
          }.to_json
        )
    end
    
    it 'enriches video questions with YouTube search when service available' do
      youtube_service = instance_double(YoutubeSearchService)
      allow(YoutubeSearchService).to receive(:new).and_return(youtube_service)
      
      allow(youtube_service).to receive(:smart_search).and_return([
        {
          video_id: 'real_video_id',
          title: 'Real Song Title',
          duration_seconds: 240
        }
      ])
      
      result = described_class.generate(params_with_video)
      
      # Check that video IDs were replaced
      video_question = result.dig('rounds', 0, 'questions', 0)
      expect(video_question.dig('media', 'video_id')).to eq('real_video_id')
      expect(video_question.dig('media', 'video_id')).not_to eq('dQw4w9WgXcQ')
    end
    
    it 'keeps placeholder video IDs when YouTube service unavailable' do
      allow(YoutubeSearchService).to receive(:new).and_raise(YoutubeSearchService::SearchError.new("API key missing"))
      
      result = described_class.generate(params_with_video)
      
      # Placeholder should remain
      video_question = result.dig('rounds', 0, 'questions', 0)
      expect(video_question.dig('media', 'video_id')).to eq('dQw4w9WgXcQ')
    end
    
    it 'logs enrichment progress' do
      youtube_service = instance_double(YoutubeSearchService)
      allow(YoutubeSearchService).to receive(:new).and_return(youtube_service)
      allow(youtube_service).to receive(:smart_search).and_return([
        { video_id: 'abc123', title: 'Test', duration_seconds: 180 }
      ])
      
      # Allow initialization logs
      allow(Rails.logger).to receive(:info).with(/YouTube service initialized/)
      
      expect(Rails.logger).to receive(:info).with(/Starting YouTube enrichment/)
      expect(Rails.logger).to receive(:info).with(/YouTube enrichment completed/)
      expect(Rails.logger).to receive(:info).with(/enrichment summary/)
      
      # Allow other info logs
      allow(Rails.logger).to receive(:info)
      
      described_class.generate(params_with_video)
    end
  end
end
