class OpenaiQuizGenerator
  class GenerationError < StandardError; end

  SYSTEM_PROMPT = <<~PROMPT
    You are Thinkn't, a quiz master that generates quizzes for team building.

    Hard rules:
    - Output MUST be valid JSON matching the provided JSON Schema.
    - Use only these question types: text, audio, video, image, true_false, multiple_choice.
    - Every question MUST include: id, type, difficulty (easy|medium|hard), prompt, answer.display.
    - Rounds MUST be progressive: round 1 easy, round 2 medium, round 3 hard.
    - Total rounds and questions per round MUST match the request.
    - For audio/video/image questions:
      - Provide media.provider ("youtube" or "static"), media.mode, and relevant fields.
      - NEVER include the official title of the song/movie in the prompt (avoid spoilers).
      - Do NOT include watch URLs. Use video_id + start_sec + end_sec.
    - For multiple_choice: provide 4 choices when possible and correct_choice_index.
    - For true_false: choices MUST be ["True","False"] and correct_choice_index must be 0 or 1.
    - Keep content inclusive and safe for work. Avoid politics, religion, sexual content, and personal attacks.
    - Tone: brainrot level is provided. For medium brainrot, be playful but readable.

    Return ONLY JSON. No markdown, no extra text.
  PROMPT

  REPAIR_PROMPT = <<~PROMPT
    Your JSON did not match the schema. Fix ONLY the JSON to satisfy the schema. Do not change the topic or counts.
    
    Validation errors:
    %{errors}
    
    Return ONLY corrected JSON.
  PROMPT

  def self.generate(params)
    new(params).generate
  end

  def initialize(params)
    @theme = params[:theme]
    @participants = params[:participants] || []
    @countries = params[:countries] || []
    @rounds = params[:rounds] || 3
    @questions_per_round = params[:questions_per_round] || 7
    @brainrot_level = params[:brainrot_level] || 'medium'
    @allowed_types = params[:allowed_types] || ['text', 'audio', 'video', 'image', 'true_false', 'multiple_choice']
    @client = OpenAI::Client.new
  end

  def generate
    quiz_json = call_openai(build_user_prompt)
    quiz_data = parse_and_validate(quiz_json)
    
    return quiz_data if quiz_data

    # Attempt repair once
    errors = get_validation_errors(quiz_json)
    repair_prompt = REPAIR_PROMPT % { errors: errors.join("\n") }
    repaired_json = call_openai(repair_prompt)
    quiz_data = parse_and_validate(repaired_json)
    
    raise GenerationError, "Failed to generate valid quiz after repair attempt" unless quiz_data
    
    quiz_data
  end

  private

  def build_user_prompt
    audience_stats = Quiz.compute_audience_stats(@participants)
    
    <<~PROMPT
      Theme: "#{@theme}"
      Participants: #{@participants.to_json}
      Countries: #{@countries.to_json}
      Allowed question types: #{@allowed_types.to_json}
      Rounds: #{@rounds}
      Questions per round: #{@questions_per_round}
      Brainrot level: #{@brainrot_level}
      
      Constraints:
      - Content should be recognizable for the demographic across listed countries.
      - Mix question types per round, but keep round 1 simplest and round 3 hardest.
      - Include short answer explanations only when useful.
      - Audience age range: #{audience_stats[:min]}-#{audience_stats[:max]} (avg: #{audience_stats[:avg]})
    PROMPT
  end

  def call_openai(user_prompt)
    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: user_prompt }
        ],
        response_format: { type: "json_object" },
        temperature: 0.8
      }
    )

    response.dig("choices", 0, "message", "content")
  rescue => e
    raise GenerationError, "OpenAI API error: #{e.message}"
  end

  def parse_and_validate(json_string)
    quiz_data = JSON.parse(json_string)
    schema_path = Rails.root.join('config', 'quiz_schema.json')
    schema = JSON.parse(File.read(schema_path))
    
    errors = JSON::Validator.fully_validate(schema, quiz_data)
    return nil unless errors.empty?
    
    quiz_data
  rescue JSON::ParserError => e
    Rails.logger.error("JSON parse error: #{e.message}")
    nil
  end

  def get_validation_errors(json_string)
    quiz_data = JSON.parse(json_string)
    schema_path = Rails.root.join('config', 'quiz_schema.json')
    schema = JSON.parse(File.read(schema_path))
    
    JSON::Validator.fully_validate(schema, quiz_data)
  rescue JSON::ParserError => e
    ["Invalid JSON: #{e.message}"]
  end
end
