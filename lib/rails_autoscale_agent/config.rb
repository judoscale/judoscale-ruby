module RailsAutoscaleAgent
  class Config
    attr_reader :api_base_url, :dyno, :pid, :fake_mode
    alias_method :fake_mode?, :fake_mode

    def initialize(environment)
      @api_base_url = environment['RAILS_AUTOSCALE_URL']
      @pid = Process.pid
      @fake_mode = true if environment['RAILS_AUTOSCALE_FAKE_MODE'] == 'true'

      if fake_mode?
        @dyno = 'web.123'
      else
        @dyno = environment['DYNO']
      end
    end

    def to_s
      "#{@dyno}##{@pid}"
    end
  end
end
