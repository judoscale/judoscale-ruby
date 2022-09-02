class SampleJob < Que::Job
  def run
    sleep rand(3)
  end
end
