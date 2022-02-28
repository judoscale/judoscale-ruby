# frozen_string_literal: true

require "judoscale/version"

module Judoscale
  class Registration < Struct.new(:collectors)
    def as_json
      {
        pid: Process.pid,
        ruby_version: RUBY_VERSION,
        rails_version: defined?(::Rails) && ::Rails.version,
        gem_version: VERSION,
        # example: { collectors: 'Web,Sidekiq' }
        collectors: collectors.map(&:collector_name).join(",")
      }
    end
  end
end
