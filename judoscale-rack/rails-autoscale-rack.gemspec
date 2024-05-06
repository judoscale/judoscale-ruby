# frozen_string_literal: true

require_relative "lib/judoscale/rack/version"

Gem::Specification.new do |spec|
  spec.name = "rails-autoscale-rack"
  spec.version = Judoscale::Rack::VERSION
  spec.authors = ["Adam McCrea", "Jon Sullivan"]
  spec.email = ["hello@judoscale.com"]

  spec.summary = "Autoscaling for Rack applications."
  spec.homepage = "https://judoscale.com"
  spec.license = "MIT"

  spec.metadata = {
    "homepage_uri" => "https://judoscale.com",
    "bug_tracker_uri" => "https://github.com/judoscale/judoscale-ruby/issues",
    "documentation_uri" => "https://judoscale.com/docs",
    "changelog_uri" => "https://github.com/judoscale/judoscale-ruby/blob/main/CHANGELOG.md",
    "source_code_uri" => "https://github.com/judoscale/judoscale-ruby"
  }

  spec.files = Dir["lib/**/*"].select { |f| f.match?(%r{rails-autoscale}) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.6.0"

  spec.add_dependency "judoscale-rack", Judoscale::Rack::VERSION
end
