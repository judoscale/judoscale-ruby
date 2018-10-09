# frozen_string_literal: true

module RailsAutoscaleAgent
  module Logger

    def logger
      @logger ||= Config.instance.logger
    end

  end
end
