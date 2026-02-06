class WikimediaSearchService
  class SearchError < StandardError; end

  # Search Wikimedia Commons for images
  def search(query, max_results: 5)
    url = "https://commons.wikimedia.org/w/api.php"
    params = {
      action: 'query',
      format: 'json',
      generator: 'search',
      gsrsearch: "#{query} filetype:bitmap",
      gsrlimit: max_results,
      gsrnamespace: 6, # File namespace
      prop: 'imageinfo',
      iiprop: 'url|size|mime',
      iiurlwidth: 800
    }

    response = HTTParty.get(url, query: params)
    
    unless response.success?
      Rails.logger.error("Wikimedia API error: #{response.code} - #{response.body}")
      raise SearchError, "Wikimedia search failed: #{response.code}"
    end

    pages = response.parsed_response.dig('query', 'pages') || {}
    
    results = pages.values.map do |page|
      image_info = page.dig('imageinfo', 0)
      next unless image_info
      
      {
        title: page['title']&.gsub('File:', ''),
        url: image_info['url'],
        thumb_url: image_info['thumburl'],
        width: image_info['width'],
        height: image_info['height']
      }
    end.compact

    results
  rescue => e
    Rails.logger.error("Wikimedia search error: #{e.message}")
    []
  end

  # Search for a specific topic with better filtering
  def smart_search(query, max_results: 3)
    # Try exact match first
    results = search(query, max_results: max_results)
    return results unless results.empty?
    
    # Try with common qualifiers
    qualifiers = ['logo', 'character', 'artwork', 'poster', 'photo']
    qualifiers.each do |qualifier|
      results = search("#{query} #{qualifier}", max_results: max_results)
      return results unless results.empty?
    end
    
    []
  end
end
