# frozen_string_literal: true

module RailsAutoscaleAgent
end

DEFAULT_WORKER_ADAPTERS = 'sidekiq,delayed_job,que,resque'

require "judoscale-ruby"
require 'rails_autoscale_agent/version'

Judoscale.configure do |config|
  config.api_base_url = ENV["RAILS_AUTOSCALE_URL"]
  config.log_level = :debug if ENV["RAILS_AUTOSCALE_DEBUG"] == "true"
end

if defined?(Rails::Railtie) && Rails::Railtie.respond_to?(:initializer)
  require "judoscale-rails"
end

adapter_names = (ENV['RAILS_AUTOSCALE_WORKER_ADAPTER'] || DEFAULT_WORKER_ADAPTERS).split(',')
adapter_names.each do |adapter_name|
  require "rails_autoscale_agent/worker_adapters/#{adapter_name}"
  adapter_constant_name = adapter_name.capitalize.gsub(/(?:_)(.)/i) { $1.upcase }
  adapter = RailsAutoscaleAgent::WorkerAdapters.const_get(adapter_constant_name).instance

  if adapter.enabled?
    require "judoscale-#{adapter_name}"

    Judoscale.configure do |config|
      config.public_send(adapter_name).track_busy_jobs = true if ENV["RAILS_AUTOSCALE_LONG_JOBS"]

      if (max_queues = ENV["RAILS_AUTOSCALE_MAX_QUEUES"])
        config.public_send(adapter_name).max_queues = max_queues.to_i
      end
    end
  end
end

# TODO: Register rails_autoscale_agent so the version info is reported
