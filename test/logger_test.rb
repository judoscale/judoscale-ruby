# frozen_string_literal: true

require "test_helper"
require "judoscale/logger"

module Judoscale
  class LoggerTest < Test
    include Logger

    def messages
      @string_io.string
    end

    def setup
      @string_io = StringIO.new
      @original_logger = ::Logger.new(@string_io)
      Config.instance.logger = @original_logger
    end

    def test_info_delegates_to_the_original_logger_prepending_judoscale
      logger.info "some info"
      assert_includes messages, "INFO -- : [Judoscale] some info"
    end

    def test_info_can_be_silenced_via_config
      use_config quiet: true do
        logger.info "some info"
        refute_includes messages, "INFO -- : [Judoscale] some info"
      end
    end

    def test_debug_silences_debug_logs_by_default
      logger.debug "silence"
      refute_includes messages, "silence"
    end

    def test_debug_includes_debug_logs_if_enabled_and_the_main_logger_level_is_DEBUG
      use_config debug: true do
        @original_logger.level = "DEBUG"
        logger.debug "some noise"
        assert_includes messages, "DEBUG -- : [Judoscale] some noise"
      end
    end

    def test_debug_includes_debug_logs_if_enabled_and_the_main_logger_level_is_INFO
      use_config debug: true do
        @original_logger.level = "INFO"
        logger.debug "some noise"
        assert_includes messages, "INFO -- : [Judoscale] [DEBUG] some noise"
      end
    end
  end
end
