module Api
  class QuizzesController < ApplicationController
    def create
      params_for_generation = generation_params
      quiz = Quiz.new(
        theme: quiz_params[:theme], 
        status: :generating,
        generation_params: params_for_generation
      )
      
      if quiz.save
        # Enqueue background job to generate quiz
        GenerateQuizJob.perform_later(quiz.id, params_for_generation)
        
        render json: {
          quiz_id: quiz.id,
          status: quiz.status
        }, status: :created
      else
        render json: { errors: quiz.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def show
      quiz = Quiz.find(params[:id])
      
      response = {
        id: quiz.id,
        status: quiz.status,
        theme: quiz.theme,
        generation_params: quiz.generation_params
      }
      
      case quiz.status
      when 'ready'
        response[:quiz] = quiz.quiz_data
      when 'failed'
        response[:error_message] = quiz.error_message
      end
      
      render json: response
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Quiz not found' }, status: :not_found
    end

    def regenerate
      quiz = Quiz.find(params[:id])
      
      # Reset quiz status to generating
      quiz.update!(status: :generating, error_message: nil, quiz_data: nil)
      
      # Use the saved generation params to regenerate
      GenerateQuizJob.perform_later(quiz.id, quiz.generation_params)
      
      render json: {
        quiz_id: quiz.id,
        status: quiz.status
      }
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Quiz not found' }, status: :not_found
    end
    
    def update
      quiz = Quiz.find(params[:id])
      
      unless quiz.ready?
        render json: { error: 'Can only edit ready quizzes' }, status: :unprocessable_entity
        return
      end
      
      # Parse and validate the quiz JSON
      quiz_data = JSON.parse(params[:quiz_data])
      
      # Validate against schema
      schema = JSON.parse(File.read(Rails.root.join('config', 'quiz_schema.json')))
      errors = JSON::Validator.fully_validate(schema, quiz_data)
      
      if errors.any?
        render json: { 
          error: 'Invalid quiz data', 
          validation_errors: errors 
        }, status: :unprocessable_entity
        return
      end
      
      quiz.update!(quiz_data: quiz_data)
      
      render json: {
        id: quiz.id,
        status: quiz.status,
        quiz: quiz.quiz_data
      }
    rescue JSON::ParserError => e
      render json: { error: "Invalid JSON: #{e.message}" }, status: :unprocessable_entity
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Quiz not found' }, status: :not_found
    end

    private

    def quiz_params
      params.require(:quiz).permit(:theme)
    rescue ActionController::ParameterMissing
      params.permit(:theme)
    end

    def generation_params
      {
        'theme' => params[:theme].to_s,
        'participants' => (params[:participants] || []).as_json,
        'rounds' => (params[:rounds] || 3).to_i,
        'questions_per_round' => (params[:questions_per_round] || 7).to_i,
        'brainrot_level' => (params[:brainrot_level] || 'medium').to_s,
        'allowed_types' => (params[:allowed_types] || ['text', 'audio', 'video', 'image', 'true_false', 'multiple_choice']).as_json
      }
    end
  end
end
