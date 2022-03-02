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
end

require "judoscale/config"
require "judoscale/version"
