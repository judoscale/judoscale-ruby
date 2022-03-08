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
    end
  end

  Config.prepend Sidekiq::Config
end
