require 'rails_helper'

RSpec.describe YoutubeSearchService do
  let(:api_key) { 'test_api_key' }
  let(:service) { described_class.new(api_key) }

  describe '#initialize' do
    it 'raises error when API key is missing' do
      allow(ENV).to receive(:[]).with('YOUTUBE_API_KEY').and_return(nil)
      expect { described_class.new }.to raise_error(YoutubeSearchService::SearchError)
    end

    it 'accepts API key parameter' do
      expect { described_class.new(api_key) }.not_to raise_error
    end
  end

  describe '#search' do
    let(:search_response) do
      {
        'items' => [
          {
            'id' => { 'videoId' => 'abc123' },
            'snippet' => { 'title' => 'Test Video' }
          }
        ]
      }
    end

    let(:video_details_response) do
      {
        'items' => [
          {
            'id' => 'abc123',
            'snippet' => {
              'title' => 'Test Video',
              'channelTitle' => 'Test Channel',
              'thumbnails' => {
                'medium' => { 'url' => 'https://example.com/thumb.jpg' }
              }
            },
            'contentDetails' => {
              'duration' => 'PT3M45S'
            }
          }
        ]
      }
    end

    before do
      stub_request(:get, /www.googleapis.com\/youtube\/v3\/search/)
        .to_return(status: 200, body: search_response.to_json, headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, /www.googleapis.com\/youtube\/v3\/videos/)
        .to_return(status: 200, body: video_details_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns search results with video details' do
      results = service.search('test query')
      
      expect(results).to be_an(Array)
      expect(results.first[:video_id]).to eq('abc123')
      expect(results.first[:title]).to eq('Test Video')
      expect(results.first[:channel]).to eq('Test Channel')
      expect(results.first[:duration_seconds]).to eq(225) # 3m45s
    end

    it 'handles search errors' do
      stub_request(:get, /www.googleapis.com\/youtube\/v3\/search/)
        .to_return(status: 403, body: { error: 'Forbidden' }.to_json)

      expect { service.search('test') }.to raise_error(YoutubeSearchService::SearchError)
    end

    it 'returns empty array when no results' do
      stub_request(:get, /www.googleapis.com\/youtube\/v3\/search/)
        .to_return(status: 200, body: { items: [] }.to_json)

      results = service.search('test query')
      expect(results).to eq([])
    end
  end

  describe '#search_music' do
    it 'appends "official audio" to query' do
      expect(service).to receive(:search).with('My Song official audio', max_results: 5)
      service.search_music('My Song')
    end
  end

  describe '#search_movie_clip' do
    it 'appends "movie scene clip" to query' do
      expect(service).to receive(:search).with('Inception movie scene clip', max_results: 5)
      service.search_movie_clip('Inception')
    end
  end

  describe '#parse_duration' do
    it 'parses ISO 8601 duration with hours, minutes, seconds' do
      duration = service.send(:parse_duration, 'PT1H30M45S')
      expect(duration).to eq(5445) # 1h30m45s = 5445 seconds
    end

    it 'parses duration with only minutes and seconds' do
      duration = service.send(:parse_duration, 'PT3M45S')
      expect(duration).to eq(225) # 3m45s = 225 seconds
    end

    it 'parses duration with only seconds' do
      duration = service.send(:parse_duration, 'PT30S')
      expect(duration).to eq(30)
    end

    it 'returns nil for invalid duration' do
      duration = service.send(:parse_duration, 'invalid')
      expect(duration).to be_nil
    end
  end
end
