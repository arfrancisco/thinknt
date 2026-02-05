FactoryBot.define do
  factory :quiz do
    theme { "90s Pop Culture" }
    status { :generating }
    
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
