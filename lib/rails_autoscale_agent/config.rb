module RailsAutoscaleAgent
  class Config
    attr_reader :api_base_url, :report_interval, :dyno, :pid, :fake_mode
    alias_method :fake_mode?, :fake_mode

    def initialize(environment)
      @api_base_url = environment['RAILS_AUTOSCALE_URL']
      @pid = Process.pid
      @fake_mode = true if environment['RAILS_AUTOSCALE_FAKE_MODE'] == 'true'

      if fake_mode?
        @dyno = 'web.123'
        @report_interval = 5
      else
        @dyno = environment['dyno']
        @report_interval = 60
      end
    end
  end
end
