# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "judoscale-rack"

require "minitest/autorun"
require "minitest/spec"
require "sinatra/base"

ENV["DYNO"] ||= "web.1"
ENV["RACK_ENV"] ||= "test"

Judoscale.configure do |config|
  config.logger = ::Logger.new(StringIO.new, progname: "rack-app")
end

class TestSinatraApp < Sinatra::Base
  use Judoscale::RequestMiddleware

  get "/" do
    "Hello World!"
  end
end
