class GenerateQuizJob < ApplicationJob
  queue_as :default

  def perform(quiz_id, generation_params)
    quiz = Quiz.find(quiz_id)
    
    begin
      quiz_data = OpenaiQuizGenerator.generate(generation_params.symbolize_keys)
      
      quiz.update!(
        quiz_data: quiz_data,
        status: :ready
      )
      
      Rails.logger.info("Quiz #{quiz_id} generated successfully")
    rescue => e
      quiz.update!(
        status: :failed,
        error_message: e.message
      )
      
      Rails.logger.error("Quiz #{quiz_id} generation failed: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
    end
  end
end
