FactoryBot.define do
  factory :quiz do
    theme { "90s Pop Culture" }
    status { :generating }
    generation_params do
      {
        'theme' => theme,
        'participants' => [],
        'rounds' => 3,
        'questions_per_round' => 7,
        'brainrot_level' => 'medium',
        'allowed_types' => ['text', 'audio', 'video', 'image', 'true_false', 'multiple_choice']
      }
    end
    
    trait :ready do
      status { :ready }
      quiz_data { JSON.parse(File.read(Rails.root.join('spec/fixtures/sample_quiz.json'))) }
    end
    
    trait :failed do
      status { :failed }
      error_message { "OpenAI API error" }
    end
  end
end
