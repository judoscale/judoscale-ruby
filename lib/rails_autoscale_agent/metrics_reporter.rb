require 'rails_autoscale_agent/autoscale_api'

# MetricsReporter wakes up every minute to send metrics to the RailsAutoscale API

module RailsAutoscaleAgent
  class MetricsReporter

    REPORT_INTERVAL_IN_SECONDS = (ENV['RAILS_AUTOSCALE_REPORT_INTERVAL_IN_SECONDS'] || 60).to_i

    def self.start(autoscale_url, store)
      return if @running

      puts "[rails-autoscale] [MetricsReporter] starting reporter, will report every #{REPORT_INTERVAL_IN_SECONDS} seconds"
      @running = true
      @autoscale_url = autoscale_url

      Thread.new do
        loop do
          sleep REPORT_INTERVAL_IN_SECONDS
          begin
            metrics = store.dump

            if metrics.any?
              puts "[rails-autoscale] [MetricsReporter] reporting #{metrics.size} metrics"
              metrics_params = MetricsParams.new(metrics)
              result = AutoscaleApi.new(@autoscale_url).report_metrics!(metrics_params.to_hash)
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
            # Exceptions in threads other than the main thread will fail silently
            # https://ruby-doc.org/core-2.2.0/Thread.html#class-Thread-label-Exception+handling
            puts "[rails-autoscale] [MetricsReporter] #{ex.inspect}"
            puts ex.backtrace.join("\n")
          end
        end
      end
    end

  end
end
