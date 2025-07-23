return unless defined?(Judoscale)

Judoscale.configure do |config|
  # Open the request catcher URL in a browser to monitor requests
  config.api_base_url = ENV["JUDOSCALE_URL"] || "https://judoscale-ruby.requestcatcher.com"

  # Enable busy jobs tracking for testing with the sample app.
  config.sidekiq.track_busy_jobs = true
end
