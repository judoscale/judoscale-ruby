# frozen_string_literal: true

require 'rails_autoscale_agent/version'

module RailsAutoscaleAgent
  class Registration < Struct.new(:config, :worker_adapters)

    def to_params
      {
        dyno: config.dyno,
        pid: Process.pid,
        ruby_version: RUBY_VERSION,
        rails_version: defined?(Rails) && Rails.version,
        gem_version: VERSION,
        # example: { worker_adapters: 'Sidekiq,Que' }
        worker_adapters: worker_adapters.map { |o| o.class.name.split('::').last }.join(','),
      }
    end
  end
end
