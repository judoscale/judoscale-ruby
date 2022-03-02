module Judoscale
  module WorkerAdapters
    module ActiveRecordHelper
      private

      def default_timezone
        if ::ActiveRecord.respond_to?(:default_timezone)
          # Rails >= 7
          ::ActiveRecord.default_timezone
        else
          # Rails < 7
          ::ActiveRecord::Base.default_timezone
        end
      end

      def select_rows_silently(sql)
        if Config.instance.log_level && ::ActiveRecord::Base.logger.respond_to?(:silence)
          ::ActiveRecord::Base.logger.silence(Config.instance.log_level) { select_rows(sql) }
        else
          select_rows(sql)
        end
      end

      def select_rows(sql)
        # This ensures the agent doesn't hold onto a DB connection any longer than necessary
        ActiveRecord::Base.connection_pool.with_connection { |c| c.select_rows(sql) }
      end
    end
  end
end
