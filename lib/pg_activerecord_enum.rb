require 'pg_enum/version'
require 'pg_enum/schema'

module PgActiveRecordEnum
  def self.define(name, values, options = {})
    values << '' if options[:allow_blank]
    return if values.blank?
    values.map!(&:to_s)
    previously_defined = values_for(name)
    if previously_defined.present? && previously_defined.sort != values.sort
      raise ArgumentError, "Enum `#{name}` already defined with other values: " +
        "#{_j(previously_defined)} (#{_j(values)} supplied)."
    elsif previously_defined.blank?
      ActiveRecord::Base.connection.execute("CREATE TYPE #{name} AS ENUM (#{_j(values)});")
    else
      ActiveRecord::Base.logger.info "Enum `#{name}` with same values already defined, skip."
    end
  end

  def self.drop(name, options = {})
    enum_dependencies = dependencies(name)
    if enum_dependencies.present?
      if options[:cascade]
        ActiveRecord::Base.connection.execute("DROP TYPE #{name} CASCADE;")
      else
        ActiveRecord::Base.logger.warn "Other objects (#{_j(enum_dependencies)}) depend on enum `#{name}`, skip."
      end
    else
      ActiveRecord::Base.connection.execute("DROP TYPE IF EXISTS #{name};")
    end
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

  def self.values_for(name)
    enum_values_sql = <<-SQL
SELECT e.enumlabel AS enum_value
FROM pg_type t
JOIN pg_enum e ON t.oid = e.enumtypid
JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
WHERE t.typname = '#{name}'
    SQL
    ActiveRecord::Base.connection.execute(enum_values_sql).map { |row| row['enum_value'] }
  end

  def self.dependencies(name)
    ActiveRecord::Base.connection.execute(
      'SELECT objid::regclass::text FROM pg_depend ' +
        "WHERE classid = 'pg_class'::regclass AND refobjid::regtype::text = '#{name}';"
    ).to_a.map(&:values).flatten
  end

  def self._j(values)
    "'#{values.join("', '")}'"
  end

  def pg_enum(name)
    enum_values = PgActiveRecordEnum.values_for(name).reject(&:blank?)
    enum name => enum_values.zip(enum_values).to_h
  end
end

require 'active_support/all'
require 'active_record'
ActiveRecord::Base.send :extend, PgActiveRecordEnum
PgActiveRecordEnum::Schema.include_migrations
