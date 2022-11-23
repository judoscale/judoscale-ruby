return unless defined?(Judoscale)

Judoscale.configure do |config|
  # Open https://judoscale-adapter-mock.requestcatcher.com in a browser to monitor requests
  config.api_base_url = ENV["JUDOSCALE_URL"] || "https://judoscale-adapter-mock.requestcatcher.com"

  # Enable busy jobs tracking for testing with the sample app.
  config.que.track_busy_jobs = true
end
