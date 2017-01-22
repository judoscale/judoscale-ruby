require 'singleton'
require 'rails_autoscale_agent/measurement'

module RailsAutoscaleAgent
  class Store
    include Singleton

    def initialize
      @metrics = []
    end

    def push(value, time = Time.now)
      puts "[rails-autoscale] [Collector] queue time: #{value}"
      @metrics << Measurement.new(time, value)
    end

    def dump
      [].tap do |result|
        while next_metric = @metrics.pop
          result << next_metric
        end
      end
    end

  end
end
