# frozen_string_literal: true

module Judoscale
  # Allows configuring Judoscale through a block, usually defined during application initialization.
  #
  # Example:
  #
  #    Judoscale.configure do |config|
  #      config.logger = MyLogger.new
  #    end
  def self.configure
    yield Config.instance
  end

  @adapters = []
  class << self
    attr_reader :adapters
  end

  Adapter = Struct.new(:identifier, :registration_info) do
    def as_json
      {identifier => registration_info}
    end
  end

  def self.register_adapter(identifier, registration_info)
    @adapters << Adapter.new(identifier, registration_info)
  end

  register_adapter :"judoscale-ruby", {
    adapter_version: VERSION,
    language_version: RUBY_VERSION
  }
end

require "judoscale/config"
require "judoscale/version"
