module RailsAutoscaleAgent
  module Logger

    def logger
      @logger ||= Config.instance.logger
    end

  end
end
