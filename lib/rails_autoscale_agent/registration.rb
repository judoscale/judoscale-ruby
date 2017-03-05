require 'rails_autoscale_agent/version'

module RailsAutoscaleAgent
  class Registration < Struct.new(:config)

    def to_params
      {
        pid: Process.pid,
        ruby_version: RUBY_VERSION,
        rails_version: Rails.version,
        gem_version: VERSION,
      }
    end
  end
end
