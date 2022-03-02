# frozen_string_literal: true

require "test_helper"

describe Judoscale do
  it "adds itself as an adapter with information to be reported to the Judoscale API" do
    adapter = Judoscale.adapters.detect { |adapter| adapter.identifier == :"judoscale-ruby" }
    _(adapter).wont_be_nil
    _(adapter.metrics_collector).must_be_nil

    registration = ::Judoscale::Registration.new(Judoscale.adapters, Judoscale::Config.instance)
    _(registration.as_json[:adapters]).must_include(:"judoscale-ruby")
  end
end
