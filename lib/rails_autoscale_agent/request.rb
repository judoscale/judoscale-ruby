module RailsAutoscaleAgent
  class Request
    attr_reader :id, :entered_queue_at, :path

    def initialize(env, config)
      @id = env['HTTP_X_REQUEST_ID']
      @path = env['PATH_INFO']
      @entered_queue_at = if unix_millis = env['HTTP_X_REQUEST_START']
                            Time.at(unix_millis.to_f / 1000)
                          elsif config.fake_mode?
                            Time.now - rand(1000) / 1000.0 # 0-1000 ms ago
                          end
    end
  end
end
