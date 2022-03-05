# frozen_string_literal: true

require "judoscale-ruby"
require "judoscale/rails/version"
require "judoscale/rails/railtie"
require "rails/version"

Judoscale.add_adapter :"judoscale-rails", {
  adapter_version: Judoscale::Rails::VERSION,
  framework_version: ::Rails.version
}
