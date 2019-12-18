# frozen_string_literal: true

require 'rails_autoscale_agent/logger'

class PumaAdapter
  include RailsAutoscaleAgent::Logger

  QUEUE = '_puma_cap'

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
    # threads are available for work. (0.5 means half are available)
    capacity = max == 0 ? 0 : server.pool_capacity.to_f / max

    # Make it an integer (0.522 becomes 52)
    capacity = (capacity * 100).round

    store.push capacity, Time.now, QUEUE

    logger.debug "puma_capacity=#{capacity}"
  end
end
