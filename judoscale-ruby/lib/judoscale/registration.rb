# frozen_string_literal: true

require "judoscale/version"

module Judoscale
  class Registration < Struct.new(:adapters, :config)
    def as_json
      {
        dyno: config.dyno,
        pid: Process.pid,
        config: config.as_json,
        adapters: adapters.each_with_object({}) { |adapter, hash|
          hash.merge!(adapter.as_json)
        }
      }
    end
  end
end
