# frozen_string_literal: true

require 'rails_autoscale_agent/config'

module ConfigHelpers
  # Override Config.instance for a single spec
  # Example:
  #   around { |example| use_config({quiet: true}, &example) }
  def use_config(options, &example)
    original_config = {}

    options.each do |key, val|
      original_config[key] = ::RailsAutoscaleAgent::Config.instance.send(key)
      ::RailsAutoscaleAgent::Config.instance.send "#{key}=", val
    end

    example.call
  ensure
    options.each do |key, val|
      ::RailsAutoscaleAgent::Config.instance.send "#{key}=", original_config[key]
    end
  end
end

RSpec.configure do |c|
  c.include ConfigHelpers
end
