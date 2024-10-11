
require 'thor'
require 'time'

module FromLiquibase

  class Column
    TABLE = {
      'bigint' => 'long',
      'boolean' => 'boolean',
      'clob' => 'String',
      'datetime' => 'OffsetDateTime',
      'decimal' => 'double',
      'int' => 'int',
      'Long' => 'Long',
      'smallint' => 'short',
      'varchar' => 'String'
    }

    attr_accessor :name, :primary_key, :nullable, :type

    def initialize(params)
      @name = params[:name]
      @type = if @name.end_with?('_id') || @name == 'id'
        'Long'
      else
        java_type(params[:type].downcase.gsub(/\(.+\)/, '')) # if params[:type]
      end
      @nullable = true
    end

    def java_type(type_name=nil)
      type_name = type if type_name.nil?

      return TABLE[type_name] if TABLE[type_name]
    rescue
      puts "Error when try to find java type for #{type_name}"
      raise
    end

    def primary_key?
      primary_key
    end
  end

  class LiquibaseLoader
    attr_accessor :table_name, :columns

    def initialize()
      @columns = []
    end

    def databaseChangeLog(h)
      yield
    end

    def changeSet(h)
      yield
    end

    def createTable(h)
      @table_name = h[:tableName]
      yield
    end

    def column(h)
      #name: 'id', type: 'bigint', autoIncrement: true
      @columns << Column.new(h)
      yield if block_given?
    end

    def constraints(h)
      unless h[:nullable].nil?
        @columns.last.nullable = h[:nullable]
      end
      if h[:primaryKey]
        @columns.last.primary_key = h[:primaryKey]
        @columns.last.type = 'Long'
      end

      yield if block_given?
    end

    def createIndex(h)
      # createIndex(tableName: 'users_user_groups', indexName: 'users_user_groups_idx', unique: true)
      # yield
    end

    def exec(f)
      puts "exec(#{f})"

      code = IO.read(f)
      eval code.gsub(/\/\/.+/, '')

      return @table_name, @columns
    end

  end

end # module

class FromLiquibaseCommand < ModelCommand

  attr_reader :arguments

  DB_DIR = "src/main/resources/db/changelog"
  #ENTITY_PATH = "#{PROJECT_ROOT}/src/main/java/de/andarte/recipes/models"

  def initialize(arguments)
    @arguments = arguments
  end

  def exec!
    puts "#{Tippfaul.project_root}/#{DB_DIR}/"

    @license_hint = Tippfaul.license_hint
    @base_package = Tippfaul.base_package

    Dir["#{Tippfaul.project_root}/#{DB_DIR}/*.groovy"].each do |f|
      # load f
      loader = FromLiquibase::LiquibaseLoader.new

      @table_name, @columns = loader.exec(f)
      @model_name = @table_name.camelize.singular

      Tippfaul.create_dirs

      render_and_write
    end
  end

end
