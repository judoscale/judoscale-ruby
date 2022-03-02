# frozen_string_literal: true

require "judoscale-ruby"
require "judoscale/rails/version"
require "judoscale/rails/railtie"
require "rails/version"

module Judoscale
  register_adapter :rails, {
    adapter_version: Judoscale::Rails::VERSION,
    framework_version: ::Rails.version
  }
end
