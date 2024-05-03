# frozen_string_literal: true

require_relative "lib/judoscale/solid_queue/version"

Gem::Specification.new do |spec|
  spec.name = "judoscale-solid_queue"
  spec.version = Judoscale::SolidQueue::VERSION
  spec.authors = ["Adam McCrea", "Carlos Antonio da Silva", "Jon Sullivan"]
  spec.email = ["hello@judoscale.com"]

  spec.summary = "Autoscaling for Solid Queue workers."
  spec.homepage = "https://judoscale.com"
  spec.license = "MIT"

  spec.metadata = {
    "homepage_uri" => "https://judoscale.com",
    "bug_tracker_uri" => "https://github.com/judoscale/judoscale-ruby/issues",
    "documentation_uri" => "https://judoscale.com/docs",
    "changelog_uri" => "https://github.com/judoscale/judoscale-ruby/blob/main/CHANGELOG.md",
    "source_code_uri" => "https://github.com/judoscale/judoscale-ruby"
  }

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7.0"

  spec.add_dependency "judoscale-ruby", Judoscale::SolidQueue::VERSION
  spec.add_dependency "solid_queue", ">= 0.3"
end
