class SampleJob < ApplicationJob
  def perform
    sleep rand(3)
  end
end
