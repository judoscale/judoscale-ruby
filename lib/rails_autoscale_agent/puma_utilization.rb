# frozen_string_literal: true

require 'rails_autoscale_agent/logger'

class PumaUtilization
  include Singleton
  include RailsAutoscaleAgent::Logger

  def initialize
    # TODO: I think this is wrong. In cluster mode, there is a server for each worker,
    # and I'm only getting stats for one.
    @server = ObjectSpace.each_object(Puma::Server).map { |obj| obj }.first if defined?(Puma::Server)
  end

  # TODO: specs
  def utilization
    return nil unless @server

    max = @server.max_threads || 0

    # Capacity is a fractional value representing how many of the total
    # threads are available for work. (0.25 means a quarter are available)
    capacity = max == 0 ? 0 : @server.pool_capacity.to_f / max

    # Utilization is a whole number percentage (0.251 capacity == 75% utilization)
    100 - (capacity * 100).round
  end
end
