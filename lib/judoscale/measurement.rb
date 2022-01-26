# frozen_string_literal: true

module Judoscale
  class Measurement < Struct.new(:metric, :time, :value, :queue_name)
    # No queue_name is assumed to be a web request measurement
    # Metrics: qt = queue time (default), qd = queue depth (needed for Resque support)
    def initialize(metric, time, value, queue_name = nil)
      super metric, time.utc, value.to_i, queue_name
    end
  end
end
