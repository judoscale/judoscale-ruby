# frozen_string_literal: true

module Judoscale
  module WorkerAdapters
    def self.load_adapters(adapter_names)
      adapter_names.map do |adapter_name|
        adapter_name = adapter_name.to_s
        require "judoscale/worker_adapters/#{adapter_name}"
        adapter_constant_name = adapter_name.capitalize.gsub(/(?:_)(.)/i) { $1.upcase }
        WorkerAdapters.const_get(adapter_constant_name).instance
      end
    end
  end
end
