# frozen_string_literal: true

require 'rails_autoscale_agent/version'

module RailsAutoscaleAgent
  class Registration < Struct.new(:config)

    def to_params
      {
        dyno: config.dyno,
        pid: Process.pid,
        ruby_version: RUBY_VERSION,
        rails_version: defined?(Rails) && Rails.version,
        gem_version: VERSION,
      }
    end
  end
end
