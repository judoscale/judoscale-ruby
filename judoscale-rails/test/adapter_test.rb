# frozen_string_literal: true

require "test_helper"

module Judoscale
  describe Rails do
    it "adds itself as an adapter with information to be reported to the Judoscale API" do
      _(::Judoscale.adapters.map(&:identifier)).must_include :"judoscale-rails"

      report = ::Judoscale::Report.new(Judoscale.adapters, Judoscale::Config.instance, [])
      _(report.as_json[:adapters]).must_include(:"judoscale-rails")
    end
  end
end
