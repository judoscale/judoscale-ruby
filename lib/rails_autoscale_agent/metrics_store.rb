require 'singleton'
module RailsAutoscaleAgent
  class MetricsStore
    include Singleton

    def initialize
      @metrics = []
    end

    def push(type, value, time = Time.now)
      puts "[rails-autoscale] [MetricsCollector] store stat: #{type}=#{value}"
      @metrics << Metric.new(type, time, value)
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
