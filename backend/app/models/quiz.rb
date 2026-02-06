class Quiz < ApplicationRecord
  enum status: { generating: 0, ready: 1, failed: 2 }

  validates :theme, presence: true
  validates :status, presence: true

  # Retry generating this quiz using the saved parameters
  def retry_generation
    update!(status: :generating, error_message: nil, quiz_data: nil)
    GenerateQuizJob.perform_later(id, generation_params)
  end

  # Validate quiz data against JSON Schema
  def validate_quiz_schema
    return false unless quiz_data.present?

    schema_path = Rails.root.join('config', 'quiz_schema.json')
    schema = JSON.parse(File.read(schema_path))

    errors = JSON::Validator.fully_validate(schema, quiz_data)
    errors.empty?
  end

  # Get detailed validation errors
  def quiz_schema_errors
    return [] unless quiz_data.present?

    schema_path = Rails.root.join('config', 'quiz_schema.json')
    schema = JSON.parse(File.read(schema_path))

    JSON::Validator.fully_validate(schema, quiz_data)
  end

  # Compute audience statistics from participants array
  def self.compute_audience_stats(participants)
    return {} if participants.blank?

    ages = participants.map { |p| p['age'] || p[:age] }.compact
    return {} if ages.empty?

    {
      min: ages.min,
      max: ages.max,
      avg: (ages.sum.to_f / ages.size).round(1)
    }
  end
end
