module RailsAutoscaleAgent
  class MetricsCollector

    def self.collect(env, store)
      if unix_millis = env['HTTP_X_REQUEST_START']
        request_start = Time.at(unix_millis.to_f / 1000)
        wait_time = Time.now - request_start

        # ensure it's a reasonable value before proceeding (under 10 minutes)
        store.push(WAIT_TIME_TYPE, wait_time) if (0..600).cover? wait_time

      elsif ENV['RAILS_AUTOSCALE_RANDOMIZE_WAIT_TIMES'] == 'true'
        random_wait_time = rand(1000) # between 0 and 1000 milliseconds
        store.push(WAIT_TIME_TYPE, random_wait_time)

      else
        puts "[rails-autoscale] [MetricsCollector] no wait time data to collect"
      end
    end

  end
end
