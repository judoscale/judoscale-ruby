# MetricsCollector collects metrics for each request, storing values in memory.

module RailsAutoscaleAgent
  class MetricsCollector

    def self.collect(env)
      if unix_millis = env['HTTP_X_REQUEST_START']
        request_start = Time.at(unix_millis.to_f / 1000)
        wait_time = Time.now - request_start

        # ensure it's a reasonable value before proceeding (under 10 minutes)
        store.push(:wait, wait_time) if (0..600).cover? wait_time
      elsif ENV['RAILS_AUTOSCALE_RANDOMIZE_WAIT_TIMES'] == 'true'
        random_wait_time = rand(1000) # between 0 and 1000 milliseconds
        store.push(:wait, random_wait_time)
      else
        puts "[rails-autoscale] [MetricsCollector] no wait time data to collect"
      end
    end

    def self.store
      MetricsStore.instance
    end
  end

  # I'm not really sure if the store and collector need to be separate classes

  require 'singleton'
  class MetricsStore
    include Singleton

    def initialize
      @metrics = []
    end

    def push(metric, value)
      puts "[rails-autoscale] [MetricsCollector] store stat: #{metric}=#{value}"
      @metrics << {dyno: ENV['DYNO'], timestamp: Time.now.iso8601, metric: metric, value: value}
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
