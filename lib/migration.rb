
require 'thor'
require 'time'

require_relative 'renderer.rb'

module Migration

  class PostgresDatatypes
    NATIVE_DATABASE_TYPES = {
      primary_key: "bigserial primary key",
      string:      { name: "character varying" },
      text:        { name: "text" },
      integer:     { name: "integer", limit: 4 },
      float:       { name: "float" },
      decimal:     { name: "decimal" },
      datetime:    {}, # set dynamically based on datetime_type
      timestamp:   { name: "timestamp" },
      timestamptz: { name: "timestamptz" },
      time:        { name: "time" },
      date:        { name: "date" },
      daterange:   { name: "daterange" },
      numrange:    { name: "numrange" },
      tsrange:     { name: "tsrange" },
      tstzrange:   { name: "tstzrange" },
      int4range:   { name: "int4range" },
      int8range:   { name: "int8range" },
      binary:      { name: "bytea" },
      boolean:     { name: "boolean" },
      xml:         { name: "xml" },
      tsvector:    { name: "tsvector" },
      hstore:      { name: "hstore" },
      inet:        { name: "inet" },
      cidr:        { name: "cidr" },
      macaddr:     { name: "macaddr" },
      uuid:        { name: "uuid" },
      json:        { name: "json" },
      jsonb:       { name: "jsonb" },
      ltree:       { name: "ltree" },
      citext:      { name: "citext" },
      point:       { name: "point" },
      line:        { name: "line" },
      lseg:        { name: "lseg" },
      box:         { name: "box" },
      path:        { name: "path" },
      polygon:     { name: "polygon" },
      circle:      { name: "circle" },
      bit:         { name: "bit" },
      bit_varying: { name: "bit varying" },
      money:       { name: "money" },
      interval:    { name: "interval" },
      oid:         { name: "oid" },
    }
  end

  class Column

    def initialize(name, type, index=nil)
      puts "New Column #{name} of #{type} with #{index}"
    end
  end

end


class MigrationCommand
  attr_reader :arguments

  DEFAULT_MIGRATION_EXTENSION = 'groovy'

  def initialize(arguments)
    @migration_name = arguments.shift
    @arguments = arguments
    @columns = []
  end

  def process_arguemnts
    @arguments.each { |column_string|
      column_def = column_string.split(':')
      @columns << Migration::Column.new(*column_def)
    }
  end

  def map_datatype(type_string)
    Migration::PostgresDatatypes::NATIVE_DATABASE_TYPES[type_string.to_sym]
  end

  def create_timestamp
    Time.now.strftime '%Y%m%d%H%M%S'
  end

  def migration_as_filename
    @migration_name.underscore
  end

  def table_name
    table_name_parts = @migration_name.underscore.split('_')

    case table_name_parts.shift.downcase
    when 'add'
      raise "add not supported yet ;-)"
      z = table_name_parts.slice(0, table_name_parts.index('to'))
      table_name_parts.join('_')
    when 'create'
      puts "create #{table_name_parts.join('_')}"
      table_name_parts.join('_')
    else
      raise "don't know what to do with #{@migration_name}"
    end

  end

  def migration_action
    table_name_parts = @migration_name.underscore.split('_')
    action = table_name_parts.shift

    action_file = case action
    when 'create'
      "create-table"
    when 'add'
      "add-column"
    else
      "Unknown action for migration: '#{action}'"
    end

    return "migration.#{action_file}"
  end

  def exec!
     process_arguemnts

     @author = ENV['USER'] || ENV['USERNAME']
     @changeSetId = "#{create_timestamp}_#{migration_as_filename}"
     @table_name = table_name
     @schemaName = nil

     puts "TableName: #{@table_name}"
     puts "Filename #{@changeSetId}.#{DEFAULT_MIGRATION_EXTENSION}"
     # create-table
     # TODO use subdirs for migration etc
     puts Renderer.new(File.join(Tippfaul.template_dir, "#{migration_action}.#{DEFAULT_MIGRATION_EXTENSION}")).render(binding)
  end

end
