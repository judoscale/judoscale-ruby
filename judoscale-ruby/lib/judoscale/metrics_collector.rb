# frozen_string_literal: true

module Judoscale
  class MetricsCollector
    def self.collect?(config)
      in_rake_task = defined?(::Rake) && Rake.respond_to?(:application) && Rake.application.top_level_tasks.any?

      !in_rake_task || in_whitelisted_rake_tasks?(config.allow_rake_tasks)
    end

    def collect
      []
    end

    def self.in_whitelisted_rake_tasks?(allowed_rake_tasks)
      # Get the tasks that were invoked from the command line.
      tasks = Rake.application.top_level_tasks

      allowed_rake_tasks.any? do |task_regex|
        tasks.any? { |task| task =~ task_regex }
      end
    end
  end
end
