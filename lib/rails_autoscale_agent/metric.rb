module RailsAutoscaleAgent
  class Metric < Struct.new(:type, :time, :value)
    def initialize(type, time, value)
      super type, time, value.to_i
    end
  end
end
