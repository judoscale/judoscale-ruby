# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rails_autoscale_agent/version'

Gem::Specification.new do |spec|
  spec.name          = "rails_autoscale_agent"
  spec.version       = RailsAutoscaleAgent::VERSION
  spec.authors       = ["Adam McCrea"]
  spec.email         = ["adam@adamlogic.com"]

  spec.summary       = "This gem works with the Rails Autoscale Heroku add-on to automatically scale your web and worker dynos."
  spec.homepage      = "https://railsautoscale.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.5.0'

  spec.add_dependency "judoscale-ruby"
  spec.add_dependency "judoscale-rails"
  spec.add_development_dependency "judoscale-sidekiq"
  spec.add_development_dependency "judoscale-resque"
  spec.add_development_dependency "judoscale-delayed_job"
  spec.add_development_dependency "judoscale-que"

  spec.metadata = {
    "homepage_uri" => "https://railsautoscale.com",
    "bug_tracker_uri" => "https://github.com/adamlogic/rails_autoscale_agent/issues",
    "documentation_uri" => "https://railsautoscale.com/docs",
    "changelog_uri" => "https://github.com/adamlogic/rails_autoscale_agent/blob/master/CHANGELOG.md",
    "source_code_uri" => "https://github.com/adamlogic/rails_autoscale_agent",
  }
end
