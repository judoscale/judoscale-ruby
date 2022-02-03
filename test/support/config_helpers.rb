# frozen_string_literal: true

require "judoscale/config"

module ConfigHelpers
  # Override Config.instance for a single spec
  # Example:
  #   use_config quiet: true do
  #     ...
  #   end
  def use_config(options, &example)
    swap_config Judoscale::Config.instance, options, example
  end

  def use_adapter_config(adapter_identifier, options, &example)
    adapter_config = Judoscale::Config.instance.public_send(adapter_identifier)
    swap_config adapter_config, options, example
  end

  # Reset config instance after each test to ensure changes don't leak to other tests.
  def after_teardown
    Judoscale::Config.instance.reset
    super
  end

  private

  def swap_config(config_instance, options, example)
    original_config = {}

    options.each do |key, val|
      original_config[key] = config_instance.public_send(key)
      config_instance.public_send "#{key}=", val
    end

    example.call
  ensure
    options.each do |key, val|
      config_instance.public_send "#{key}=", original_config[key]
    end
  end
end

Judoscale::Test.include ConfigHelpers
