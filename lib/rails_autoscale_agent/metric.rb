module RailsAutoscaleAgent
  class Metric < Struct.new(:type, :time, :value)
  end
end
