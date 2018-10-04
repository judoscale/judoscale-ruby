module RailsAutoscaleAgent
  module Logger

    def logger
      @logger ||= defined?(Rails) ? Rails.logger : ::Logger.new(STDOUT)
    end

  end
end
