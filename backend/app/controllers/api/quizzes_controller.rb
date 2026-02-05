module Api
  class QuizzesController < ApplicationController
    def create
      quiz = Quiz.new(theme: quiz_params[:theme], status: :generating)
      
      if quiz.save
        # Enqueue background job to generate quiz
        GenerateQuizJob.perform_later(quiz.id, generation_params)
        
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
        theme: quiz.theme
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
      # Stub for M3 milestone
      render json: { error: 'Not implemented yet' }, status: :not_implemented
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
        'countries' => (params[:countries] || []).as_json,
        'rounds' => (params[:rounds] || 3).to_i,
        'questions_per_round' => (params[:questions_per_round] || 7).to_i,
        'brainrot_level' => (params[:brainrot_level] || 'medium').to_s,
        'allowed_types' => (params[:allowed_types] || ['text', 'audio', 'video', 'image', 'true_false', 'multiple_choice']).as_json
      }
    end
  end
end
