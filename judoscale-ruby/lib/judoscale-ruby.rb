# frozen_string_literal: true

require "rails_autoscale/config"
require "rails_autoscale/version"

module RailsAutoscale
  # Allows configuring Rails Autoscale through a block, usually defined during application initialization.
  #
  # Example:
  #
  #    RailsAutoscale.configure do |config|
  #      config.logger = MyLogger.new
  #    end
  def self.configure
    yield Config.instance
  end

  @adapters = []
  class << self
    attr_reader :adapters
  end

  Adapter = Struct.new(:identifier, :adapter_info, :metrics_collector) do
    def as_json
      {identifier => adapter_info}
    end
  end

  def self.add_adapter(identifier, adapter_info, metrics_collector: nil, expose_config: nil)
    Config.expose_adapter_config(expose_config) if expose_config
    @adapters << Adapter.new(identifier, adapter_info, metrics_collector)
  end

  add_adapter :"rails-autoscale-core", {
    adapter_version: VERSION,
    language_version: RUBY_VERSION
  }
end
