class RakeMock
  def initialize(top_level_tasks = [])
    @top_level_tasks = top_level_tasks
  end

  def application
    Application.new(@top_level_tasks)
  end

  class Application < Struct.new(:top_level_tasks)
  end
end
