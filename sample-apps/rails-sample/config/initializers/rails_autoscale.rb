return unless defined?(Judoscale)

Judoscale.configure do |config|
  # Open https://rails-autoscale-agent-mock.requestcatcher.com in a browser to monitor requests
  config.api_base_url = "https://rails-autoscale-agent-mock.requestcatcher.com"
end
