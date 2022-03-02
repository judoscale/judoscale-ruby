# frozen_string_literal: true

require "test_helper"

module Judoscale
  describe Rails do
    it "registers itself as an adapter with information to be registered with the Judoscale API" do
      _(::Judoscale.adapters.map(&:identifier)).must_include :"judoscale-rails"

      registration = ::Judoscale::Registration.new(Judoscale::Config.instance)
      _(registration.as_json[:adapters]).must_include(:"judoscale-rails")
    end
  end
end
