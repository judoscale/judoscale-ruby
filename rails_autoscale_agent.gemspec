# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rails_autoscale_agent/version'

Gem::Specification.new do |spec|
  spec.name          = "rails_autoscale_agent"
  spec.version       = RailsAutoscaleAgent::VERSION
  spec.authors       = ["Adam McCrea"]
  spec.email         = ["adam@adamlogic.com"]

  spec.summary       = "This gem works with the Rails Autoscale Heroku add-on to automatically scale your web dynos."
  spec.homepage      = "https://github.com/adamlogic/rails_autoscale_agent"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '~> 2.5'
end
