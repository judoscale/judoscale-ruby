require "./hello"

RailsAutoscale.configure do |config|
  # Open https://rails-autoscale-adapter-mock.requestcatcher.com in a browser to monitor requests
  config.api_base_url = ENV["RAILS_AUTOSCALE_URL"] || "https://rails-autoscale-adapter-mock.requestcatcher.com"
end

use RailsAutoscale::RequestMiddleware
run Sinatra::Application
