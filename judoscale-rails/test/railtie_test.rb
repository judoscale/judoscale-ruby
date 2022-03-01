# frozen_string_literal: true

require "test_helper"

module Judoscale
  describe Judoscale::Rails::Railtie do
    it "uses the Rails.logger when initialized though Rails" do
      _(::Judoscale::Config.instance.logger).must_equal ::Rails.logger
    end

    it "inserts the request middleware into the application middleware" do
      _(::Rails.application.config.middleware).must_include Judoscale::RequestMiddleware
    end
  end
end
