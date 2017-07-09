$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rails_autoscale_agent'
require 'active_support/tagged_logging'

module Rails
  def self.logger
    @logger ||= ActiveSupport::TaggedLogging.new(::Logger.new('log/test.log'))
  end

  def self.version
    '5.0.fake'
  end
end
