class YoutubeSearchService
  class SearchError < StandardError; end

  def initialize(api_key = nil)
    @api_key = api_key || ENV['YOUTUBE_API_KEY']
    raise SearchError, "YouTube API key not configured" unless @api_key
  end

  # Search for videos matching a query
  # Returns array of hashes with video_id, title, duration
  def search(query, max_results: 5, video_category: nil)
    url = "https://www.googleapis.com/youtube/v3/search"
    params = {
      part: 'snippet',
      q: query,
      type: 'video',
      maxResults: max_results,
      key: @api_key,
      videoEmbeddable: 'true',
      videoSyndicated: 'true',
      order: 'relevance',  # Order by relevance
      safeSearch: 'none'
    }

    # Add video category if specified (10 = Music)
    params[:videoCategoryId] = video_category if video_category

    response = HTTParty.get(url, query: params)

    unless response.success?
      Rails.logger.error("YouTube API error: #{response.code} - #{response.body}")
      raise SearchError, "YouTube search failed: #{response.code}"
    end

    results = response.parsed_response['items'] || []
    video_ids = results.map { |item| item.dig('id', 'videoId') }.compact

    # Get video details including duration
    return [] if video_ids.empty?

    get_video_details(video_ids)
  end

  # Get detailed info about specific videos
  def get_video_details(video_ids)
    url = "https://www.googleapis.com/youtube/v3/videos"
    params = {
      part: 'snippet,contentDetails',
      id: video_ids.join(','),
      key: @api_key
    }

    response = HTTParty.get(url, query: params)

    unless response.success?
      Rails.logger.error("YouTube API error: #{response.code} - #{response.body}")
      raise SearchError, "YouTube video details failed: #{response.code}"
    end

    items = response.parsed_response['items'] || []
    items.map do |item|
      {
        video_id: item['id'],
        title: item.dig('snippet', 'title'),
        channel: item.dig('snippet', 'channelTitle'),
        duration_seconds: parse_duration(item.dig('contentDetails', 'duration')),
        thumbnail: item.dig('snippet', 'thumbnails', 'medium', 'url')
      }
    end
  end

  # Search for music/songs
  def search_music(query, max_results: 5)
    # Try official music video first
    results = search("#{query} official music video", max_results: max_results, video_category: '10')
    return results unless results.empty?

    # Fallback to official audio
    search("#{query} official audio", max_results: max_results, video_category: '10')
  end

  # Search for movie clips
  def search_movie_clip(query, max_results: 5)
    search("#{query} movie scene clip", max_results: max_results)
  end

  # Smart search that tries multiple strategies
  def smart_search(query, type: 'video', max_results: 3)
    case type
    when 'audio'
      # For audio, prioritize official releases
      keywords = ['official music video', 'official audio', 'official video', 'lyrics video']
    when 'video'
      # For video, try official first, then popular
      keywords = ['official video', 'official music video', 'music video']
    else
      keywords = ['']
    end

    # Try each keyword until we get good results
    keywords.each do |keyword|
      search_query = keyword.empty? ? query : "#{query} #{keyword}"
      results = search(search_query, max_results: max_results, video_category: (type == 'audio' ? '10' : nil))

      unless results.empty?
        # Filter results to prefer ones with "official" in title
        official_results = results.select { |r| r[:title].downcase.include?('official') }
        return official_results unless official_results.empty?
        return results
      end
    end

    []
  end

  private

  # Parse ISO 8601 duration (e.g., "PT3M45S" -> 225 seconds)
  def parse_duration(iso_duration)
    return nil unless iso_duration

    match = iso_duration.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/)
    return nil unless match

    hours = (match[1] || 0).to_i
    minutes = (match[2] || 0).to_i
    seconds = (match[3] || 0).to_i

    (hours * 3600) + (minutes * 60) + seconds
  end
end
