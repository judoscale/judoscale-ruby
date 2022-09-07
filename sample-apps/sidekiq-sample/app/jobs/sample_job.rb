class SampleJob
  include Sidekiq::Job

  def perform
    sleep rand(3)
  end
end
