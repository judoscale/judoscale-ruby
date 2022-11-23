module Judoscale
  module Resque
    module LatencyExtension
      # Store the time when jobs are pushed to the queue in order to calculate latency.
      def push(queue, item)
        item["timestamp"] = Time.now.utc.to_f
        super
      end

      # Calculate latency for the given queue using the stored timestamp of the oldest item in the queue.
      def latency(queue)
        if (item = peek(queue))
          timestamp = item["timestamp"]
          timestamp ? Time.now.utc.to_f - timestamp.to_f : 0.0
        else
          0.0
        end
      end
    end
  end
end

::Resque.extend(Judoscale::Resque::LatencyExtension)
