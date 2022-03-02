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

  def self.register_adapter(adapter)
    @adapters << adapter
  end

  module Ruby
    def self.adapter_registration
      {
        "judoscale-ruby": {
          adapter_version: VERSION,
          language_version: RUBY_VERSION
        }
      }
    end
  end

  register_adapter Ruby
end

require "judoscale/config"
require "judoscale/version"
