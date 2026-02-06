Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    allowed = ENV.fetch('CORS_ORIGINS', 'http://localhost:5173,http://localhost:3001,http://localhost:8080')
    origins *allowed.split(',').map(&:strip)

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
