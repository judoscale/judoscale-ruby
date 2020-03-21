# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pry'
require 'rails_autoscale_agent'
require_relative './support/env_helpers'

module Rails
  def self.logger
    @logger ||= ::Logger.new('log/test.log')
  end

  def self.version
    '5.0.fake'
  end
end

RSpec.configure do |c|
  c.before(:example) { Singleton.__init__(RailsAutoscaleAgent::Config) if Object.const_defined?('RailsAutoscaleAgent::Config') }
end
