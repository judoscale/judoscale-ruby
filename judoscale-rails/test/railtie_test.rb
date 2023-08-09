# frozen_string_literal: true

require "test_helper"
require "minitest/stub_const"

module Judoscale
  describe Judoscale::Rails::Railtie do
    it "uses the Rails.logger when initialized though Rails" do
      _(::Judoscale::Config.instance.logger).must_equal ::Rails.logger
    end

    it "inserts the request middleware into the application middleware" do
      _(::Rails.application.config.middleware).must_include Judoscale::RequestMiddleware
    end

    # TODO: Fix this test. It fails because Rails initialization has already run in test_helper.
    # it "skips the request middleware if running Rails console" do
    #   ::Rails.stub_const :Console, Module.new do
    #     _(::Rails.application.config.middleware).wont_include Judoscale::RequestMiddleware
    #   end
    # end

    it "boots up a reporter automatically after the app/config is initialized" do
      _(::Judoscale::Reporter.instance).must_be :started?
    end
  end
end
