# frozen_string_literal: true

require "judoscale/version"

module Judoscale
  class Registration < Struct.new(:config)
    def as_json
      {
        dyno: config.dyno,
        pid: Process.pid,
        # example: { collectors: 'Web,Sidekiq' }
        # collectors: collectors.map(&:collector_name).join(","),
        # TODO: adapters instead.
        adapters: config.adapters.each_with_object({}) { |adapter, hash|
          hash.merge!(adapter.as_json)
        }
      }
    end
  end
end
