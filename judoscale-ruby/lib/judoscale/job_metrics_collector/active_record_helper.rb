module Judoscale
  class JobMetricsCollector
    module ActiveRecordHelper
      # Cleanup any whitespace characters (including new lines) from the SQL for simpler logging.
      # Reference: ActiveSupport's `squish!` method. https://api.rubyonrails.org/classes/String.html#method-i-squish
      def self.cleanse_sql(sql)
        sql.gsub(/[[:space:]]+/, " ").strip
      end

      private

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
