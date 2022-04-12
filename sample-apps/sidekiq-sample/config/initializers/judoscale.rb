Judoscale.configure do |config|
  # Open https://judoscale-adapter-mock.requestcatcher.com in a browser to monitor requests
  config.api_base_url = "https://judoscale-adapter-mock.requestcatcher.com"

  # Enable busy jobs tracking for testing with the sample app.
  config.sidekiq.track_busy_jobs = true
end
