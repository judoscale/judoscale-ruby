# frozen_string_literal: true

require "judoscale-ruby"
require "judoscale/rails/version"
require "judoscale/rails/railtie"
require "rails/version"

module Judoscale
  module Rails
    def self.adapter_registration
      {
        "judoscale-rails": {
          adapter_version: Judoscale::Rails::VERSION,
          framework_version: ::Rails.version
        }
      }
    end
  end

  register_adapter Rails
end
