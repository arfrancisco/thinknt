class OpenaiQuizGenerator
  class GenerationError < StandardError; end

  def self.system_prompt
    schema = JSON.parse(File.read(Rails.root.join('config', 'quiz_schema.json')))
    
    <<~PROMPT
      You are Thinkn't, a quiz master that generates quizzes for team building.

      CRITICAL: Your output MUST be valid JSON matching this EXACT schema:

      ```json
      #{JSON.pretty_generate(schema)}
      ```

      ABSOLUTE REQUIREMENTS - FAILURE TO FOLLOW THESE WILL RESULT IN REJECTION:
      
      1. THEME ADHERENCE: EVERY SINGLE QUESTION must be directly related to the provided theme.
         - If theme is "90s music", ALL questions must be about 90s songs, artists, albums, etc.
         - Do NOT include generic trivia questions unrelated to the theme.
      
      2. QUESTION TYPES: Use ONLY the question types listed in "allowed_types".
         - If allowed_types is ["audio", "video"], you MUST NOT use text, multiple_choice, or true_false.
         - Respect this constraint strictly for every question.
      
      3. DIFFICULTY PROGRESSION:
         - Round 1: easy difficulty
         - Round 2: medium difficulty  
         - Round 3: hard difficulty
         - Every question MUST include: id, type, difficulty (easy|medium|hard), prompt, answer.display.
      
      4. MEDIA REQUIREMENTS:
         - For YouTube: Use ONLY the video_id (11-character YouTube ID from a REAL video)
         - For YouTube: Include start_sec and end_sec as integers (seconds)
         - For images: Use image_url with a complete, REAL URL to an actual accessible image
         - NEVER use placeholder URLs like "example.com" or fake/example video IDs
         - For audio/video questions: NEVER include the song/movie title in the prompt (avoid spoilers)
      
      5. MULTIPLE CHOICE & TRUE/FALSE:
         - For multiple_choice: provide 4 choices and correct_choice_index
         - For true_false: choices MUST be ["True","False"] and correct_choice_index must be 0 or 1
      
      6. CONTENT GUIDELINES:
         - Keep content inclusive and safe for work
         - Avoid politics, religion, sexual content, and personal attacks
         - Match the provided brainrot level tone

      Return ONLY JSON. No markdown, no extra text.
    PROMPT
  end

  def self.repair_prompt(errors, schema)
    <<~PROMPT
      Your JSON did not match the required schema. Fix ONLY the JSON structure to satisfy the schema. Do not change the topic or counts.

      Required schema:
      ```json
      #{JSON.pretty_generate(schema)}
      ```

      Validation errors found:
      #{errors.join("\n")}

      Return ONLY the corrected JSON matching the schema above.
    PROMPT
  end

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
    schema = load_schema
    repair_prompt = self.class.repair_prompt(errors, schema)
    repaired_json = call_openai(repair_prompt)
    quiz_data = parse_and_validate(repaired_json)

    raise GenerationError, "Failed to generate valid quiz after repair attempt" unless quiz_data

    quiz_data
  end

  private

  def build_user_prompt
    audience_stats = Quiz.compute_audience_stats(@participants)

    <<~PROMPT
      ========================================
      THEME: "#{@theme}"
      ========================================
      
      CRITICAL: Every question MUST be about "#{@theme}". Do NOT include generic trivia!
      
      REQUIREMENTS:
      - Participants: #{@participants.to_json}
      - Countries: #{@countries.to_json}
      - ALLOWED QUESTION TYPES (use ONLY these): #{@allowed_types.to_json}
      - Rounds: #{@rounds}
      - Questions per round: #{@questions_per_round}
      - Brainrot level: #{@brainrot_level}
      - Audience age range: #{audience_stats[:min]}-#{audience_stats[:max]} (avg: #{audience_stats[:avg]})

      THEME REQUIREMENTS:
      - ALL #{@rounds * @questions_per_round} questions must relate directly to: "#{@theme}"
      - Content should be recognizable for people from: #{@countries.join(", ")}
      - If the theme is about music, use audio questions with real song clips
      - If the theme is about movies, use video questions with real movie clips
      - Make questions progressively harder: Round 1 (easy), Round 2 (medium), Round 3 (hard)

      STRICT TYPE CONSTRAINT:
      You may ONLY use these question types: #{@allowed_types.to_json}
      Do NOT use any other question types!

      MEDIA INSTRUCTIONS:
      For YouTube videos/audio:
      - Find REAL YouTube videos that match the theme "#{@theme}"
      - Use the actual 11-character video_id (e.g., for Spice Girls - Wannabe use "gJLIiF15wjQ")
      - Choose recognizable clips with start_sec and end_sec
      - DO NOT reveal the answer in the prompt - make them guess from the clip!
      
      For images:
      - Use REAL Wikimedia Commons URLs: "https://upload.wikimedia.org/wikipedia/commons/..."
      - Choose iconic images related to "#{@theme}"
      - DO NOT use placeholder URLs

      Remember: Theme is "#{@theme}" - EVERY question must be about this topic!
    PROMPT
  end

  def call_openai(user_prompt)
    response = @client.chat(
      parameters: {
        model: "gpt-4o",
        messages: [
          { role: "system", content: self.class.system_prompt },
          { role: "user", content: user_prompt }
        ],
        response_format: { type: "json_object" },
        temperature: 0.7
      }
    )

    response.dig("choices", 0, "message", "content")
  rescue => e
    raise GenerationError, "OpenAI API error: #{e.message}"
  end

  def parse_and_validate(json_string)
    quiz_data = JSON.parse(json_string)
    schema = load_schema

    errors = JSON::Validator.fully_validate(schema, quiz_data)
    return nil unless errors.empty?

    quiz_data
  rescue JSON::ParserError => e
    Rails.logger.error("JSON parse error: #{e.message}")
    nil
  end

  def get_validation_errors(json_string)
    quiz_data = JSON.parse(json_string)
    schema = load_schema

    JSON::Validator.fully_validate(schema, quiz_data)
  rescue JSON::ParserError => e
    ["Invalid JSON: #{e.message}"]
  end

  def load_schema
    schema_path = Rails.root.join('config', 'quiz_schema.json')
    JSON.parse(File.read(schema_path))
  end
end
