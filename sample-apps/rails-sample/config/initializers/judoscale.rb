return unless defined?(Judoscale)

Judoscale.configure do |config|
  # Open the request catcher URL in a browser to monitor requests
  config.api_base_url = ENV["JUDOSCALE_URL"] || "https://judoscale-ruby.requestcatcher.com"
  config.rake_task_ignore_regex = /assets:|db:|middleware/
  # config.start_reporter_after_initialize = false
end
