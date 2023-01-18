class SampleJob < ApplicationJob
  def self.perform
    sleep rand(3)
  end
end
