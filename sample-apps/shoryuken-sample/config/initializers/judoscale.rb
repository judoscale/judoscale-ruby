return unless defined?(Judoscale)

Judoscale.configure do |config|
  # Open the request catcher URL in a browser to monitor requests
  config.api_base_url = ENV["JUDOSCALE_URL"] || "https://judoscale-ruby.requestcatcher.com"

  # Shoryuken does not support tracking busy jobs yet.
  # config.shoryuken.track_busy_jobs = true

  # List queue names so we can track from web process as well,
  # since Shoryuken only knows about them on the worker process.
  config.shoryuken.queues = %w[high default low]
end
