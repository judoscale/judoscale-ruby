require 'rails_autoscale_agent/logger'

module RailsAutoscaleAgent
  class Collector
    extend Logger

    def self.collect(request, store)
      if request.entered_queue_at
        if request.entered_queue_at < (Time.now - 60 * 10)
          # ignore unreasonable values
          logger.debug "[Collector] request queued for more than 10 minutes... skipping collection"
        else
          queue_time_millis = (Time.now - request.entered_queue_at) * 1000
          queue_time_millis = 0 if queue_time_millis < 0
          store.push(queue_time_millis)
        end
      else
        logger.debug "[Collector] no wait time data to collect"
      end
    end

  end
end
