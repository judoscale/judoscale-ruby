# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rails-autoscale-web"

require "minitest/autorun"
require "minitest/spec"

ENV["DYNO"] ||= "web.1"
ENV["RACK_ENV"] ||= "test"
require "action_controller"

class TestRailsApp < Rails::Application
  config.secret_key_base = "test-secret"
  config.eager_load = false
  config.logger = ::Logger.new(StringIO.new, progname: "rails-app")
  routes.append do
    root to: proc {
      [200, {"Content-Type" => "text/plain"}, ["Hello World"]]
    }
  end
  initialize!
end
