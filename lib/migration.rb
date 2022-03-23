
require_relative 'renderer.rb'

class Migration
  attr_reader :arguments

  def initialize(arguments)
    @arguments = arguments
  end

  def process_arguemnts
  end

  def exec!
     process_arguemnts

     puts Renderer.new(File.join(Tippfaul.TEMPLATE_DIR, 'migration.groovy.erb'), self)
  end

end
