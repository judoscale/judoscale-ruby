return unless defined?(Judoscale)

Judoscale.configure do |config|
  # Open https://requestinspector.com/p/judoscale-ruby in a browser to monitor requests
  config.api_base_url = ENV["JUDOSCALE_URL"] || "https://requestinspector.com/inspect/judoscale-ruby"

  # Enable busy jobs tracking for testing with the sample app.
  config.sidekiq.track_busy_jobs = true
end
