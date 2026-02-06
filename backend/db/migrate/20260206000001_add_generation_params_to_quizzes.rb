class AddGenerationParamsToQuizzes < ActiveRecord::Migration[7.1]
  def change
    add_column :quizzes, :generation_params, :json
  end
end
