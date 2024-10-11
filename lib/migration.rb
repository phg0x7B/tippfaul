
require 'thor'
require 'time'
require 'fileutils'

require_relative 'renderer.rb'

module Migration

  class PostgresDatatypes
    NATIVE_DATABASE_TYPES = {
      primary_key: { name: "bigserial"}, # primary key
      references:  { name: "bigint", suffix: '_id' }, # foreign key
      string:      { name: "text" },
      text:        { name: "text" },
      integer:     { name: "integer", limit: 4 },
      long:        { name: "bigint" },
      bigint:        { name: "bigint" },
      float:       { name: "float" },
      decimal:     { name: "decimal" },
      datetime:    { name: "date" }, # set dynamically based on datetime_type
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

  class JavaDatatypes
      NATIVE_DATABASE_TYPES = {
          primary_key: { name: "Long"},
          references:  { name: "Long", suffix: 'Id' },
          string:      { name: "String" },
          text:        { name: "String" },
          integer:     { name: "Integer", limit: 4 },
          bigint:      { name: "Long" },
          long:        { name: "long" },
          float:       { name: "Float" },
          decimal:     { name: "BigDecimal" },
          datetime:    { name: "LocalDateTime" }, # set dynamically based on datetime_type
          timestamp:   { name: "Timestamp" },
          timestamptz: { name: "Timestamp" },
          time:        { name: "LocalTime" },
          date:        { name: "LocalDate" },
          daterange:   { name: "i have no clue" },
          numrange:    { name: "i have no clue numrange" },
          tsrange:     { name: "i have no clue" },
          tstzrange:   { name: "i have no clue" },
          int4range:   { name: "i have no clue" },
          int8range:   { name: "i have no clue" },
          binary:      { name: "Byte" },
          boolean:     { name: "Boolean" },
          xml:         { name: "String" },
          tsvector:    { name: "i have no clue" },
          hstore:      { name: "i have no clue" },
          inet:        { name: "i have no clue" },
          cidr:        { name: "i have no clue cidr" },
          macaddr:     { name: "i have no clue macaddr" },
          uuid:        { name: "UUID" },
          json:        { name: "i have no clue json" },
          jsonb:       { name: "i have no clue jsonb" },
          ltree:       { name: "i have no clue ltree" },
          citext:      { name: "i have no clue citext" },
          point:       { name: "i have no clue point" },
          line:        { name: "i have no clue line" },
          lseg:        { name: "i have no clue lseg" },
          box:         { name: "i have no clue box" },
          path:        { name: "i have no clue path" },
          polygon:     { name: "i have no clue polygon" },
          circle:      { name: "i have no clue circle" },
          bit:         { name: "i have no clue bit" },
          bit_varying: { name: "i have no clue bit varying" },
          money:       { name: "Money" },
          interval:    { name: "i have no clue interval" },
          oid:         { name: "i have no clue oid" },
          }
  end

  class Column
    attr_reader :name, :type, :index

    def initialize(name, type, index=nil)
      @name, @type, @index = name, type, index
      @alias_type = type
    end

    def sql_type
      # puts "Try type #{type}"
      PostgresDatatypes::NATIVE_DATABASE_TYPES[type.to_sym][:name]
    end

    def java_type
        JavaDatatypes::NATIVE_DATABASE_TYPES[type.to_sym][:name]
    rescue
      puts "Error when try to find java type for #{type}"
      raise
    end

    def primary_key?
      @alias_type == 'primary_key'
    end

    def constraints?
      primary_key? || index
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
    @acton_from_tablename = nil
    @table_name_parts = nil
    @license_hint = Tippfaul.license_hint
    @base_package = Tippfaul.base_package
  end

  def process_arguemnts
    got_primary_key = false
    if action_from_tablename[0] == 'add'
      got_primary_key = true
    end

    @arguments.each { |column_string|
      column_def = column_string.split(':')
      @columns << Migration::Column.new(*column_def)
      got_primary_key = true if column_def[1] == 'primary_key'
    }

    @columns.unshift(Migration::Column.new('id', 'primary_key')) unless got_primary_key
  end

  def create_timestamp
    Time.now.strftime '%Y%m%d%H%M%S'
  end

  def migration_as_filename
    @migration_name.underscore
  end

  def join_table_name(table_name_parts)
    return table_name_parts.join('_').pluralize
  end

  def join_table_name_after_keyword(table_name_parts, keyword)
    index = table_name_parts.index(keyword) + 1
    return table_name_parts[index, table_name_parts.length - 1].join('_').pluralize
  end

  def table_name
    action, table_name_parts = action_from_tablename
    return case action
    when 'create'
      puts "create #{table_name_parts.join('_')}"
      join_table_name(table_name_parts)
    when 'add'
      puts "add to #{table_name_parts.join('_')}"
      join_table_name_after_keyword(table_name_parts, 'to')
    else
      puts "fallback: #{@migration_name.underscore}"
      @migration_name.underscore.pluralize
    end
  end

  def migration_action
    action_file = case action_from_tablename[0]
    when 'create'
      "create-table"
    when 'add'
      "add-column"
    else
      "empty"
    end

    return "migration.#{action_file}"
  end

  def action_from_tablename
    if @acton_from_tablename.nil?
      @table_name_parts = @migration_name.underscore.split('_')
      @acton_from_tablename = @table_name_parts.shift
    end
    return @acton_from_tablename, @table_name_parts
  end

  def attr(str, obj)
    unless obj.nil?
      return "#{str}: '#{obj}',"
    end
  end

  def open_target(outfile_name, &block)
    raise "#{outfile_name} already exists" if File.exist? outfile_name

    File.open(outfile_name, 'wb') do |out|
      yield(out)
    end
  end

  def exec!
    process_arguemnts

    @author = ENV['USER'] || ENV['USERNAME']
    @changeSetId = "#{create_timestamp}_#{migration_as_filename}"
    @table_name = table_name
    @schemaName = nil

    puts "TableName: #{@table_name}"
    open_target(Tippfaulmain_resources_dir('db', 'changelog', "#{@changeSetId}.#{DEFAULT_MIGRATION_EXTENSION}")) do |out|
      out.puts Renderer.new(File.join(Tippfaul.template_dir, "#{migration_action}.#{DEFAULT_MIGRATION_EXTENSION}")).render(binding)
    end
  end

end

class ModelCommand < MigrationCommand
  def initialize(arguments)
    super(arguments)
  end

  def exec!
    super

    @model_name = @table_name.camelize.singular

    Tippfaul.create_dirs

    render_and_write
  end

  def render_and_write
    FileUtils.mkdir_p(Tippfaul.main_dir(@model_name))
    FileUtils.mkdir_p(Tippfaul.test_dir(@model_name))
    FileUtils.mkdir_p(Tippfaul.integration_test_src_dir(@model_name))
    FileUtils.mkdir_p(Tippfaul.fixtures_dir(@model_name))

    open_target(Tippfaul.main_dir(@model_name, "#{@model_name}Entity.java")) do |out|
        out.puts Renderer.new(File.join(Tippfaul.template_dir, "entity.java")).render(binding)
    end
    open_target(Tippfaul.test_dir(@model_name, "#{@model_name}EntityTest.java")) do |out|
        out.puts Renderer.new(File.join(Tippfaul.template_dir, "entity-test.java")).render(binding)
    end
    open_target(Tippfaul.main_dir(@model_name, "#{@model_name}Repository.java")) do |out|
        out.puts Renderer.new(File.join(Tippfaul.template_dir, "repository.java")).render(binding)
    end
    open_target(Tippfaul.integration_test_src_dir(@model_name, "#{@model_name}RepositoryIntegrationTest.java")) do |out|
        out.puts Renderer.new(File.join(Tippfaul.template_dir, "repository-test.java")).render(binding)
    end
    open_target(Tippfaul.fixtures_dir("#{@table_name}.csv")) do |out|
        out.puts @columns.map{|c| "\"#{c.name.underscore}\"" }.join(',')
        # out.puts "-1, ,\"2022-04-28 20:21:47.376006\",\"2022-04-28 20:21:47.376006\""
    end
    open_target(Tippfaul.main_dir(@model_name, "#{@model_name}Dto.java")) do |out|
        out.puts Renderer.new(File.join(Tippfaul.template_dir, "dto.java")).render(binding)
    end
    open_target(Tippfaul.main_dir(@model_name, "#{@model_name}Mapper.java")) do |out|
        out.puts Renderer.new(File.join(Tippfaul.template_dir, "mapper.java")).render(binding)
    end
    open_target(Tippfaul.main_dir(@model_name, "#{@model_name}Service.java")) do |out|
      out.puts Renderer.new(File.join(Tippfaul.template_dir, "service.java")).render(binding)
    end
    open_target(Tippfaul.main_dir(@model_name, "#{@model_name}ServiceImpl.java")) do |out|
      out.puts Renderer.new(File.join(Tippfaul.template_dir, "service-impl.java")).render(binding)
    end
  end

end
