# frozen_string_literal: true

require_relative "lib/judoscale/sidekiq/version"

Gem::Specification.new do |spec|
  spec.name = "rails-autoscale-sidekiq"
  spec.version = Judoscale::Sidekiq::VERSION
  spec.authors = ["Adam McCrea", "Carlos Antonio da Silva", "Jon Sullivan"]
  spec.email = ["hello@judoscale.com"]

  spec.summary = "Autoscaling for Sidekiq workers."
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

  spec.add_dependency "judoscale-sidekiq", Judoscale::Sidekiq::VERSION
end
