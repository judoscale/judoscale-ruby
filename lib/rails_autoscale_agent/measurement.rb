# frozen_string_literal: true

module RailsAutoscaleAgent
  class Measurement < Struct.new(:time, :value, :queue_name)
    def initialize(time, value, queue_name = nil)
      super time.utc, value.to_i, queue_name
    end
  end
end
