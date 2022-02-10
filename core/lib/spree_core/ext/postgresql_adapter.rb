require 'active_record/connection_adapters/postgresql_adapter'

module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter
      # set_standard_conforming_strings needed to be changed for Postgres >= 12
      # https://stackoverflow.com/questions/58763542
      def set_standard_conforming_strings
        old, self.client_min_messages = client_min_messages, 'warning'
        execute('SET standard_conforming_strings = on', 'SCHEMA') rescue nil
      ensure
        self.client_min_messages = old
      end
    end
  end
end
