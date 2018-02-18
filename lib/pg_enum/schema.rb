module PgEnum
  module Schema
    def self.included(_)
      ActiveRecord::ConnectionAdapters::Table.send :include, TableDefinition
      ActiveRecord::ConnectionAdapters::TableDefinition.send :include, TableDefinition
      ActiveRecord::ConnectionAdapters::AbstractAdapter.send :include, Statements
      ActiveRecord::Migration::CommandRecorder.send :include, CommandRecorder
    end

    module Statements
      def add_enum(table_name, *enum_names)
        raise ArgumentError, 'Please specify enum name in your add_enum call in your migration.' if enum_names.empty?

        options = enum_names.extract_options!
        values = options.delete(:values)

        raise ArgumentError, 'Please specify values for enum in your migration.' if values.blank?

        enum_names.each do |enum_name|
          PgEnum.define enum_name, values
          add_column(table_name, enum_name, enum_name, options)
        end
      end

      def remove_enum(table_name, *enum_names)
        raise ArgumentError, 'Please specify enum name in your add_enum call in your migration.' if enum_names.empty?

        enum_names.extract_options!

        enum_names.each do |enum_name|
          remove_column(table_name, enum_name)
          PgEnum.drop enum_name
        end
      end
    end

    module TableDefinition
      def enum(*enum_names)
        options = enum_names.extract_options!
        values = options.delete(:values)

        raise ArgumentError, 'Please specify values for enum in your migration.' if values.blank?

        enum_names.each do |enum_name|
          PgEnum.define enum_name, values
          column(enum_name, enum_name, options)
        end
      end
    end

    module CommandRecorder
      def add_enum(*args)
        record(:add_enum, args)
      end

      private

      def invert_add_enum(args)
        [:remove_enum, args]
      end
    end
  end
end
