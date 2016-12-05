module RailsAutoscaleAgent
  class MetricsCollector

    def self.collect(env, store)
      if unix_millis = env['HTTP_X_REQUEST_START']
        request_start = Time.at(unix_millis.to_f / 1000)
        wait_time_millis = (Time.now - request_start) * 1000

        # ensure it's a reasonable value before proceeding (under 10 minutes)
        store.push(WAIT_TIME_TYPE, wait_time_millis) if (0..600_000).cover? wait_time_millis

      elsif ENV['RAILS_AUTOSCALE_RANDOMIZE_WAIT_TIMES'] == 'true'
        random_wait_time_millis = rand(1000) # between 0 and 1000 milliseconds
        store.push(WAIT_TIME_TYPE, random_wait_time_millis)

      else
        puts "[rails-autoscale] [MetricsCollector] no wait time data to collect"
      end
    end

  end
end
