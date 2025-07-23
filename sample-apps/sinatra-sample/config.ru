require "./hello"

Judoscale.configure do |config|
  # Open the request catcher URL in a browser to monitor requests
  config.api_base_url = ENV["JUDOSCALE_URL"] || "https://judoscale-ruby.requestcatcher.com"
end

use Judoscale::RequestMiddleware
run Sinatra::Application
