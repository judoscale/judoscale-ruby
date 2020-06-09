# frozen_string_literal: true

module RailsAutoscaleAgent
  class Measurement < Struct.new(:time, :value, :queue_name, :metric)
    # No queue_name is assumed to be a web request measurement
    # Metrics: qt = queue time (default), qd = queue depth (needed for Resque support)
    def initialize(time, value, queue_name = nil, metric = nil)
      super time.utc, value.to_i, queue_name, metric
    end
  end
end
