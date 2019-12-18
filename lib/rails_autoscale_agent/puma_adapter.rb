# frozen_string_literal: true

require 'rails_autoscale_agent/logger'

class PumaAdapter
  include RailsAutoscaleAgent::Logger

  QUEUE = '_puma_util'

  def enabled?
    server.present?
  end

  def server
    @puma_server ||= ObjectSpace.each_object(Puma::Server).map { |obj| obj }.first if defined?(Puma::Server)
  end

  # TODO: specs
  def collect!(store)
    max = server.max_threads || 0

    # Capacity is a fractional value representing how many of the total
    # threads are available for work. (0.25 means a quarter are available)
    capacity = max == 0 ? 0 : server.pool_capacity.to_f / max

    # Utilization is a whole number percentage (0.251 capacity == 75% utilization)
    utilization = 100 - (capacity * 100).round

    store.push utilization, Time.now, QUEUE

    logger.debug "puma_util=#{utilization}"
  end
end
