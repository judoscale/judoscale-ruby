# frozen_string_literal: true

module Judoscale
  class Metric < Struct.new(:identifier, :time, :value, :queue_name)
    # No queue_name is assumed to be a web request metric
    # Metrics: qt = queue time (default), qd = queue depth, busy
    def initialize(identifier, time, value, queue_name = nil)
      super identifier, time.utc, value.to_i, queue_name
    end
  end
end
