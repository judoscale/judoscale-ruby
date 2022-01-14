# frozen_string_literal: true

require "judoscale/config"

module ConfigHelpers
  # Override Config.instance for a single spec
  # Example:
  #   use_config quiet: true do
  #     ...
  #   end
  def use_config(options, &example)
    original_config = {}

    options.each do |key, val|
      original_config[key] = ::Judoscale::Config.instance.send(key)
      ::Judoscale::Config.instance.send "#{key}=", val
    end

    example.call
  ensure
    options.each do |key, val|
      ::Judoscale::Config.instance.send "#{key}=", original_config[key]
    end
  end

  # Reset config instance after each test to ensure changes don't leak to other tests.
  def after_teardown
    Singleton.__init__(Judoscale::Config)
    super
  end
end

Judoscale::Test.include ConfigHelpers
