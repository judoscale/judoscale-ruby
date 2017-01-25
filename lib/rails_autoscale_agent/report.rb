module RailsAutoscaleAgent
  class Report < Struct.new(:time, :values)

    def initialize(time, values = [])
      super
    end

    def to_params(config)
      {
        time: time.iso8601,
        dyno: config.dyno,
        pid: config.pid,
        measurements: values,
      }
    end
  end
end
