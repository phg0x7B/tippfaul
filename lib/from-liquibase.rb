
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
      'smallint' => 'short',
      'varchar' => 'String'
    }

    attr_accessor :name, :primaryKey, :nullable, :type

    def initialize(params)
      @name = params[:name]
      @type = if @name.end_with?('_id') || @name == 'id'
        'Long'
      else
        translate_type(params[:type].downcase.gsub(/\(.+\)/, '')) # if params[:type]
      end
      @nullable = true
    end

    def translate_type(type)
      return TABLE[type] if TABLE[type]
      raise "Unknown type #{type}"
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
        @columns.last.primaryKey = h[:primaryKey]
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

class FromLiquibaseCommand

  attr_reader :arguments

  DB_DIR = "src/main/resources/db/changelog"
  #ENTITY_PATH = "#{PROJECT_ROOT}/src/main/java/de/andarte/recipes/models"

  def initialize(arguments)
    @arguments = arguments
  end

  def exec!
    puts "#{Tippfaul.project_root}/#{DB_DIR}/"

    Dir["#{Tippfaul.project_root}/#{DB_DIR}/*.groovy"].each do |f|
      # load f
      loader = FromLiquibase::LiquibaseLoader.new

      @table_name, @columns = loader.exec(f)

      # TODO load ERB templates
      # TODO add license notes to each java file

      puts Renderer.new(File.join(Tippfaul.template_dir, "lb-dto.java")).render(binding)
    end
  end

end
