# frozen_string_literal: true

require "judoscale/version"

module Judoscale
  class Registration < Struct.new(:worker_adapters)
    def to_params
      {
        pid: Process.pid,
        ruby_version: RUBY_VERSION,
        rails_version: defined?(Rails) && Rails.version,
        gem_version: VERSION,
        # example: { worker_adapters: 'Sidekiq,Que' }
        worker_adapters: worker_adapters.map { |o| o.class.adapter_name }.join(",")
      }
    end
  end
end
