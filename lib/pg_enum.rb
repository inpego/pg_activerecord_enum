require 'pg_enum/version'

module PgEnum

  def self.define(name, values, options = {})
    values << '' if options[:allow_blank]
    ActiveRecord::Base.connection.execute("CREATE TYPE #{name} AS ENUM ('#{values.join("', '")}');")
  end

  def self.drop(name)
    ActiveRecord::Base.connection.execute("DROP TYPE #{name};")
  end

  def self.change(name, values, options = {})
    drop(name)
    define(name, values, options)
  end

  def self.add_values(name, values)
    values.each do |value|
      ActiveRecord::Base.connection.execute("ALTER TYPE #{name} ADD VALUE '#{value}';")
    end
  end

  def self.allow_blank_for(name)
    add_values(name, [''])
  end

  def pg_enum(name, options = {})
    enum_values = ApplicationRecord.connection.execute(
      <<~SQL
                      SELECT e.enumlabel AS enum_value
                      FROM pg_type t
                      JOIN pg_enum e ON t.oid = e.enumtypid
                      JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
                      WHERE t.typname = '#{name}'
    SQL
    )
    enum_values = enum_values.map { |row| row['enum_value'] }
    enum_values << '' if options[:allow_blank]
    enum name => enum_values.zip(enum_values).to_h
  end

end

require 'active_support/all'
require 'active_record'
ActiveRecord::Base.send :extend, PgEnum

