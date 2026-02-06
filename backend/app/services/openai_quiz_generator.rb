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
    
    begin
      @youtube_service = YoutubeSearchService.new
      Rails.logger.info("YouTube service initialized successfully")
    rescue => e
      @youtube_service = nil
      Rails.logger.warn("YouTube service not available: #{e.message}")
    end
    
    begin
      @wikimedia_service = WikimediaSearchService.new
      Rails.logger.info("Wikimedia service initialized successfully")
    rescue => e
      @wikimedia_service = nil
      Rails.logger.warn("Wikimedia service not available: #{e.message}")
    end
  end

  def generate
    quiz_json = call_openai(build_user_prompt)
    quiz_data = parse_and_validate(quiz_json)

    unless quiz_data
      # Attempt repair once
      errors = get_validation_errors(quiz_json)
      schema = load_schema
      repair_prompt = self.class.repair_prompt(errors, schema)
      repaired_json = call_openai(repair_prompt)
      quiz_data = parse_and_validate(repaired_json)

      raise GenerationError, "Failed to generate valid quiz after repair attempt" unless quiz_data
    end

    # Enrich video/audio questions with real YouTube searches
    if @youtube_service
      Rails.logger.info("Starting YouTube enrichment...")
      enrich_with_youtube_search(quiz_data)
      Rails.logger.info("YouTube enrichment completed")
    else
      Rails.logger.warn("Skipping YouTube enrichment - service not available")
    end
    
    # Enrich image questions with real Wikimedia images
    if @wikimedia_service
      Rails.logger.info("Starting Wikimedia enrichment...")
      enrich_with_wikimedia_search(quiz_data)
      Rails.logger.info("Wikimedia enrichment completed")
    else
      Rails.logger.warn("Skipping Wikimedia enrichment - service not available")
    end

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
      - Use placeholder video_id "dQw4w9WgXcQ" - we will replace it with actual search results
      - Set start_sec to 10 and end_sec to 25 as defaults - we will adjust these automatically
      - DO NOT reveal the answer in the prompt - make them guess from the clip!
      - Make sure the answer.display field contains searchable text (e.g., "Artist - Song Title" or "Movie Title scene")

      For images:
      - Use REAL Wikimedia Commons URLs: "https://upload.wikimedia.org/wikipedia/commons/..."
      - Choose iconic images related to "#{@theme}"
      - DO NOT use placeholder URLs
      - IMPORTANT: Only use image questions for public domain content (historical figures, landmarks, nature, etc.)
      - AVOID image questions for copyrighted characters, logos, or modern media (use video/audio instead)

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
        temperature: 0.8
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

  def enrich_with_youtube_search(quiz_data)
    total_questions = 0
    enriched_count = 0
    
    quiz_data['rounds']&.each do |round|
      round['questions']&.each do |question|
        next unless ['audio', 'video'].include?(question['type'])
        next unless question.dig('media', 'provider') == 'youtube'
        
        total_questions += 1

        # Build search query from answer
        answer_text = question.dig('answer', 'display')
        unless answer_text
          Rails.logger.warn("Question #{question['id']} has no answer.display - skipping")
          next
        end

        Rails.logger.info("Searching YouTube for: #{answer_text} (type: #{question['type']})")
        
        begin
          # Use smart search for better results
          results = @youtube_service.smart_search(answer_text, type: question['type'], max_results: 3)
          
          if results.empty?
            Rails.logger.warn("No YouTube results found for: #{answer_text}")
            next
          end

          video = results.first
          duration = video[:duration_seconds] || 300
          
          # Update the question with actual video ID and reasonable time range
          question['media']['video_id'] = video[:video_id]
          question['media']['start_sec'] = calculate_start_time(duration)
          question['media']['end_sec'] = calculate_end_time(duration, question['media']['start_sec'])
          
          enriched_count += 1
          Rails.logger.info("✓ Enriched #{question['id']}: #{video[:title]} (#{video[:video_id]})")
        rescue => e
          Rails.logger.error("Failed to enrich question #{question['id']}: #{e.class} - #{e.message}")
          Rails.logger.error(e.backtrace.first(5).join("\n"))
          # Keep the placeholder video_id as fallback
        end
      end
    end
    
    Rails.logger.info("YouTube enrichment summary: #{enriched_count}/#{total_questions} questions enriched")
  end
  
  def enrich_with_wikimedia_search(quiz_data)
    total_questions = 0
    enriched_count = 0
    
    quiz_data['rounds']&.each do |round|
      round['questions']&.each do |question|
        next unless question['type'] == 'image'
        next unless question.dig('media', 'provider') == 'static'
        
        total_questions += 1

        # Build search query from answer
        answer_text = question.dig('answer', 'display')
        unless answer_text
          Rails.logger.warn("Question #{question['id']} has no answer.display - skipping")
          next
        end

        Rails.logger.info("Searching Wikimedia for: #{answer_text}")
        
        begin
          results = @wikimedia_service.smart_search(answer_text, max_results: 3)
          
          if results.empty?
            Rails.logger.warn("No Wikimedia results found for: #{answer_text}")
            # Use a placeholder image with the answer text
            question['media']['image_url'] = "https://via.placeholder.com/800x600/4A5568/FFFFFF?text=#{CGI.escape(answer_text)}"
            Rails.logger.info("Using placeholder for #{question['id']}")
            next
          end

          image = results.first
          
          # Update the question with actual image URL
          question['media']['image_url'] = image[:url]
          
          enriched_count += 1
          Rails.logger.info("✓ Enriched #{question['id']}: #{image[:title]} (#{image[:url]})")
        rescue => e
          Rails.logger.error("Failed to enrich question #{question['id']}: #{e.class} - #{e.message}")
          Rails.logger.error(e.backtrace.first(5).join("\n"))
          # Use placeholder as fallback
          question['media']['image_url'] = "https://via.placeholder.com/800x600/4A5568/FFFFFF?text=#{CGI.escape(answer_text || 'Image')}"
        end
      end
    end
    
    Rails.logger.info("Wikimedia enrichment summary: #{enriched_count}/#{total_questions} questions enriched")
  end

  def build_search_query(answer_text, question_type)
    case question_type
    when 'audio'
      "#{answer_text} official audio"
    when 'video'
      "#{answer_text} official video"
    else
      answer_text
    end
  end

  def calculate_start_time(duration)
    # Start somewhere in first third of video, but not in first 5 seconds
    max_start = [duration / 3, duration - 20].min
    [5, rand(5..max_start.to_i)].max
  end

  def calculate_end_time(duration, start_sec)
    # Play 10-15 seconds
    clip_length = rand(10..15)
    end_time = start_sec + clip_length
    [end_time, duration - 1].min
  end
end
