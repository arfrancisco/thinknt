Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow local development origins
    origins 'http://localhost:5173', 'http://localhost:3001'

    # TODO: Add your production frontend URL after deployment
    # Example: 'https://your-app-name-frontend.herokuapp.com'
    # or Netlify/Vercel URLs

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
