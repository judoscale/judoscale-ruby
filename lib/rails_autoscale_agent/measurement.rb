module RailsAutoscaleAgent
  class Measurement < Struct.new(:time, :value)
    def initialize(time, value)
      super time.utc, value.to_i
    end
  end
end
