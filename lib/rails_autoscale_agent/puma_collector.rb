# frozen_string_literal: true

require 'rails_autoscale_agent/puma_utilization'

module RailsAutoscaleAgent
  class PumaCollector
    QUEUE = '_puma_util'

    def self.start!(store)
      sample_interval = 0.1 # 10x/sec

      Thread.new do
        loop do
          sleep sample_interval

          if puma_util = PumaUtilization.instance.utilization
            store.push puma_util, Time.now, QUEUE
          end
        end
      end
    end
  end
end
