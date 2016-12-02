require 'rails_autoscale_agent/autoscale_api'

# MetricsReporter wakes up every minute to send metrics to the RailsAutoscale API

module RailsAutoscaleAgent
  class MetricsReporter

    REPORT_INTERVAL_IN_SECONDS = (ENV['RAILS_AUTOSCALE_REPORT_INTERVAL_IN_SECONDS'] || 60).to_i

    # Why did I choose for MetricsReporter to use a class instance var, but
    # MetricsStore is a singleton?
    def self.start(autoscale_url)
      return if @running

      puts "[rails-autoscale] [MetricsReporter] starting reporter, will report every #{REPORT_INTERVAL_IN_SECONDS} seconds"
      @running = true
      @autoscale_url = autoscale_url

      Thread.new do
        loop do
          sleep REPORT_INTERVAL_IN_SECONDS
          begin
            metrics = MetricsCollector.store.dump

            if metrics.any?
              puts "[rails-autoscale] [MetricsReporter] reporting #{metrics.size} metrics"
              result = AutoscaleApi.new(@autoscale_url).report_metrics!(metrics)
              case result
              when AutoscaleApi::SuccessResponse
                puts "[rails-autoscale] [MetricsReporter] ok"
              when AutoscaleApi::FailureResponse
                puts "[rails-autoscale] [MetricsReporter] failed: #{result.failure_message}"
              end
            else
              puts "[rails-autoscale] [MetricsReporter] nothing to report"
            end
          rescue => ex
            puts "[rails-autoscale] [MetricsReporter] #{ex.inspect}"
            puts ex.backtrace.join("\n")
          end
        end
      end
    end

  end
end
