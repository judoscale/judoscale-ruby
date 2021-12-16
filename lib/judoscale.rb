# frozen_string_literal: true

module Judoscale
end

require "judoscale/version"
require "judoscale/railtie" if defined?(Rails::Railtie) && Rails::Railtie.respond_to?(:initializer)
