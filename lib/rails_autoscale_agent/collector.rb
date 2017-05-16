require 'rails_autoscale_agent/logger'

module RailsAutoscaleAgent
  class Collector
    extend Logger

    def self.collect(request, store)
      if request.entered_queue_at
        if request.entered_queue_at < (Time.now - 60 * 10)
          # ignore unreasonable values
          logger.info "request queued for more than 10 minutes... skipping collection"
        else
          queue_time_millis = ((Time.now - request.entered_queue_at) * 1000).to_i
          queue_time_millis = 0 if queue_time_millis < 0
          store.push(queue_time_millis)
          logger.info "Collected queue_time=#{queue_time_millis}ms request_id=#{request.id}"
        end
      end
    end

  end
end
