# frozen_string_literal: true

require "test_helper"

module Judoscale
  describe Judoscale::Ruby do
    it "registers itself as an adapter" do
      _(::Judoscale.adapters).must_include Judoscale::Ruby
    end

    it "dumps adapter information to register with Judoscale API" do
      registration = ::Judoscale::Registration.new(Judoscale::Config.instance)
      _(registration.as_json[:adapters]).must_include(:"judoscale-ruby")
    end
  end
end
