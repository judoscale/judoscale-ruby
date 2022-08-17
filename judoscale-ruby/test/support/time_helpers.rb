# frozen_string_literal: true

module TimeHelpers
  def freeze_time(time = Time.now.utc, &block)
    Time.stub(:now, time, &block)
  end
end

RailsAutoscale::Test.include(TimeHelpers)
