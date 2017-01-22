module RailsAutoscaleAgent
  class Collector

    def self.collect(request, store)
      if request.entered_queue_at
        if request.entered_queue_at < (Time.now - 60 * 10)
          # ignore unreasonable values
          puts "[rails-autoscale] [Collector] request queued for more than 10 minutes... skipping collection"
        else
          queue_time_millis = (Time.now - request.entered_queue_at) * 1000
          store.push(queue_time_millis)
        end
      else
        puts "[rails-autoscale] [Collector] no wait time data to collect"
      end
    end

  end
end
