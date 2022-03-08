# frozen_string_literal: true

require "judoscale/config"

module Judoscale
  module Sidekiq
    module Config
      attr_reader :sidekiq

      def reset
        super
        @sidekiq = Judoscale::Config::WorkerAdapterConfig.new(:sidekiq)
      end

      def as_json
        json = super
        json[:sidekiq] = sidekiq.as_json
        json
      end
    end
  end

  Config.prepend Sidekiq::Config
end
