module RailsAutoscaleAgent
  class Metric < Struct.new(:type, :time, :value)
    def initialize(type, time, value)
      super type, time.utc, value.to_i
    end
  end
end
