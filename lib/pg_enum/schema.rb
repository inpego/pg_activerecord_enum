module PgEnum
  module Schema
    def self.include_migrations
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
          PgEnum.define enum_name, values, options
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

      def drop_table_with_enums(table_name, enums, *args, &block)
        drop_table(table_name, *args, &block)
        enums.each { |enum_name| PgEnum.drop enum_name }
      end
    end

    module TableDefinition
      def enum(*enum_names)
        options = enum_names.extract_options!
        values = options.delete(:values)

        raise ArgumentError, 'Please specify values for enum in your migration.' if values.blank?

        enum_names.each do |enum_name|
          PgEnum.define enum_name, values, options
          column(enum_name, enum_name, options)
        end
      end
    end

    module CommandRecorder
      def add_enum(*args)
        record(:add_enum, args)
      end

      private

      def invert_create_table(args)
        table_name = args.first
        enums = ActiveRecord::Base.connection.columns(table_name).select do |column|
          column.sql_type_metadata.type == :enum
        end
        if enums.present?
          args.shift
          [:drop_table_with_enums, [table_name, enums.map(&:name)] + args]
        else
          [:drop_table, args]
        end
      end

      def invert_add_enum(args)
        [:remove_enum, args]
      end
    end
  end
end
