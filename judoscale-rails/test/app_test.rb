require "test_helper"
require "rack/test"

module Judoscale
  describe "App Request Metrics" do
    include Rack::Test::Methods

    def app
      # This refers to TestRailsApp created in test_helper.rb
      ::Rails.application
    end

    after {
      MetricsStore.instance.clear
    }

    it "tracks request metrics for each request" do
      header "X-Request-Start", (Time.now.to_i - 10).to_s

      1.upto(3) { |i|
        get "/"

        _(last_response).must_be :ok?
        _(last_response.body).must_equal "Hello World"

        _(MetricsStore.instance.metrics.size).must_equal i
        _(MetricsStore.instance.metrics.last.identifier).must_equal :qt
      }
    end
  end
end
