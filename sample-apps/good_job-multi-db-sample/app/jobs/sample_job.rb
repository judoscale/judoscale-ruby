class SampleJob < ApplicationJob
  retry_on StandardError, wait: 30.seconds, attempts: 3

  def perform
    sleep 5
  end
end
