require "./hello"

Judoscale.configure do |config|
  # Open https://requestinspector.com/p/judoscale-ruby in a browser to monitor requests
  config.api_base_url = ENV["JUDOSCALE_URL"] || "https://requestinspector.com/inspect/judoscale-ruby"
end

use Judoscale::RequestMiddleware
run Sinatra::Application
