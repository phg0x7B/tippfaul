
require 'erb'
require 'colorize'
require 'thor'

Dir[File.join(__dir__, 'extensions', '*.rb')].each { |file| require file }

require_relative 'lib/migration.rb'
# Dir[File.join(__dir__, 'lib', '*.rb')].each { |file| require file }

# https://guides.rubygems.org/make-your-own-gem/

module Tippfaul

  def self.template_dir
    return File.join(__dir__, 'templates')
  end

end

# view.rb
#class View
  #attr_reader :name

  #def initialize
    #@name = "Jonathan"
  #end

  #def benediction
    #Time.now.hour >= 12 ? "Have a wonderful afternoon!" : "Have a wonderful morning!"
  #end

  #def get_binding
    #binding
  #end

  #def build
    #Renderer.new(self)
  #end
#end

class TippfaulCLI < Thor
  class_option :verbose, :type => :boolean, :aliases => "-v"

  desc "new DIRECTORY", "Create a new rails app"

  def new
    # ...
  end

  desc "generate THING PARAMETERS", "Generate migration / model"

  def generate(thing, *parameters)

    command = case thing
    when 'migration', 'm'
      puts "Create a new migration #{parameters}"
      MigrationCommand.new(parameters)

    else
      raise "Sorry, #{thing} is not supported yet."
    end

    command.exec!
  end

end

TippfaulCLI.start(ARGV)
