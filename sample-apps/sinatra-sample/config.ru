require "./hello"

Judoscale.configure do |config|
  # Open https://judoscale-adapter-mock.requestcatcher.com in a browser to monitor requests
  config.api_base_url = ENV["JUDOSCALE_URL"] || "https://judoscale-adapter-mock.requestcatcher.com"
end

use Judoscale::RequestMiddleware
run Sinatra::Application
