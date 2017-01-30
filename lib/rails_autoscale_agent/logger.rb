module RailsAutoscaleAgent
  module Logger

    def logger
      @logger ||= Rails.logger
    end

  end
end
