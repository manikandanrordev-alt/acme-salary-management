# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    frontend_urls = ENV.fetch("FRONTEND_URL", "http://localhost:5173")
                       .split(",")
                       .map(&:strip)
                       .reject(&:empty?)

    origins(*frontend_urls,
            "http://127.0.0.1:5173",
            "http://localhost:3000",
            "http://127.0.0.1:3000",
            /\Ahttps:\/\/.*\.vercel\.app\z/,
            /\Ahttps:\/\/.*\.onrender\.com\z/)

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      expose: [ "X-CSRF-Token" ],
      credentials: true
  end
end
