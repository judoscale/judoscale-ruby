# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rails_autoscale_agent/version'

Gem::Specification.new do |spec|
  spec.name          = "rails_autoscale_agent"
  spec.version       = RailsAutoscaleAgent::VERSION
  spec.authors       = ["Adam McCrea"]
  spec.email         = ["adam@adamlogic.com"]

  spec.summary       = "[DEPRECATED] Please use the rails-autoscale-web gem"
  spec.homepage      = "https://railsautoscale.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.5.0'
  spec.post_install_message  = <<~MSG
    DEPRECATION WARNING: rails_autoscale_agent is no longer maintained.
    Please install rails-autoscale-web instead.
    See https://github.com/rails-autoscale/rails-autoscale-gems for more.
  MSG

  spec.metadata = {
    "homepage_uri" => "https://railsautoscale.com",
    "bug_tracker_uri" => "https://github.com/rails-autoscale/rails-autoscale-gems/issues",
    "documentation_uri" => "https://railsautoscale.com/docs",
    "changelog_uri" => "https://github.com/rails-autoscale/rails-autoscale-gems/blob/master/CHANGELOG.md",
    "source_code_uri" => "https://github.com/rails-autoscale/rails-autoscale-gems",
  }
end
