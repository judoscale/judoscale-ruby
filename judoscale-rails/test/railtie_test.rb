# frozen_string_literal: true

require "test_helper"

module Judoscale
  describe Judoscale::Rails::Railtie do
    it "inserts the request middleware into the application middleware" do
      _(TestRailsApp.config.middleware).must_include Judoscale::RequestMiddleware
      _(log_string).must_include "Preparing request middleware"
    end
  end
end
