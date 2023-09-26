# frozen_string_literal: true

require "test_helper"
require "judoscale/rails/config"

module Judoscale
  describe Judoscale::Rails::Config do
    it "adds the start_reporter_after_initialize config option" do
      _(::Judoscale::Config.instance.start_reporter_after_initialize).must_equal true
    end
  end
end
