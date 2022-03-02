module LogHelpers
  @log_io = StringIO.new
  @logger = ::Logger.new(@log_io)

  class << self
    attr_reader :log_io, :logger
  end

  def log_string
    LogHelpers.log_io.string
  end

  def clear_log
    LogHelpers.log_io.reopen
  end

  def after_teardown
    clear_log
    super
  end
end

Judoscale::Test.include(LogHelpers)
