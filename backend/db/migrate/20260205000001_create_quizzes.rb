class CreateQuizzes < ActiveRecord::Migration[7.1]
  def change
    create_table :quizzes do |t|
      t.string :theme, null: false
      t.integer :status, default: 0, null: false
      t.json :quiz_data
      t.text :error_message

      t.timestamps
    end

    add_index :quizzes, :status
  end
end
