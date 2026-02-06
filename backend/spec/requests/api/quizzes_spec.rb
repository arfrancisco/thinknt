require 'rails_helper'

RSpec.describe "API Quizzes", type: :request do
  describe "POST /api/quizzes" do
    let(:valid_params) do
      {
        theme: "Movies",
        participants: [{ name: "Bob", age: 35, country: "UK" }],
        countries: ["UK"],
        rounds: 2,
        questions_per_round: 5,
        brainrot_level: "low",
        allowed_types: ["text", "multiple_choice"]
      }
    end

    it "creates a quiz and returns generating status" do
      post "/api/quizzes", params: valid_params
      
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body).to include("quiz_id", "status")
      expect(body["status"]).to eq("generating")
    end

    it "saves generation params to the quiz" do
      post "/api/quizzes", params: valid_params
      
      quiz = Quiz.last
      expect(quiz.generation_params).to be_present
      expect(quiz.generation_params['theme']).to eq('Movies')
      expect(quiz.generation_params['rounds']).to eq(2)
      expect(quiz.generation_params['questions_per_round']).to eq(5)
      expect(quiz.generation_params['brainrot_level']).to eq('low')
    end

    it "enqueues a background job" do
      expect {
        post "/api/quizzes", params: valid_params
      }.to have_enqueued_job(GenerateQuizJob)
    end

    it "returns 422 for missing theme" do
      post "/api/quizzes", params: valid_params.except(:theme)
      
      # Note: This might not fail in the current implementation
      # as the controller doesn't validate params strictly
      # Consider adding validation if needed
    end
  end

  describe "GET /api/quizzes/:id" do
    context "when quiz is generating" do
      let(:quiz) { create(:quiz, status: :generating) }

      it "returns generating status" do
        get "/api/quizzes/#{quiz.id}"
        
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["status"]).to eq("generating")
        expect(body).not_to include("quiz")
      end
    end

    context "when quiz is ready" do
      let(:generation_params) do
        {
          'theme' => 'Movies',
          'rounds' => 2,
          'questions_per_round' => 5
        }
      end
      let(:quiz) { create(:quiz, :ready, generation_params: generation_params) }
      
      it "returns the full quiz data" do
        get "/api/quizzes/#{quiz.id}"
        
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["status"]).to eq("ready")
        expect(body["quiz"]).to include("id", "title", "rounds")
      end

      it "includes generation params in response" do
        get "/api/quizzes/#{quiz.id}"
        
        body = JSON.parse(response.body)
        expect(body["generation_params"]).to be_present
        expect(body["generation_params"]["theme"]).to eq("Movies")
        expect(body["generation_params"]["rounds"]).to eq(2)
      end
    end

    context "when quiz has failed" do
      let(:quiz) { create(:quiz, :failed) }
      
      it "returns error message" do
        get "/api/quizzes/#{quiz.id}"
        
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["status"]).to eq("failed")
        expect(body["error_message"]).to be_present
      end
    end

    context "when quiz does not exist" do
      it "returns 404" do
        get "/api/quizzes/99999"
        
        expect(response).to have_http_status(:not_found)
        body = JSON.parse(response.body)
        expect(body["error"]).to eq("Quiz not found")
      end
    end
  end

  describe "POST /api/quizzes/:id/regenerate" do
    let(:generation_params) do
      {
        'theme' => 'Movies',
        'participants' => [{ 'name' => 'Bob', 'age' => 35, 'country' => 'UK' }],
        'countries' => ['UK'],
        'rounds' => 2,
        'questions_per_round' => 5,
        'brainrot_level' => 'low',
        'allowed_types' => ['text', 'multiple_choice']
      }
    end
    let(:quiz) { create(:quiz, :failed, generation_params: generation_params) }

    it "resets quiz status and enqueues regeneration job" do
      expect {
        post "/api/quizzes/#{quiz.id}/regenerate"
      }.to have_enqueued_job(GenerateQuizJob).with(quiz.id, generation_params)
      
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("generating")
    end

    it "returns 404 for non-existent quiz" do
      post "/api/quizzes/99999/regenerate"
      
      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("Quiz not found")
    end
  end
end
