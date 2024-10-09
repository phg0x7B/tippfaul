#!/usr/bin/env ruby

require 'erb'
require 'colorize'
require 'thor'

Dir[File.join(__dir__, 'extensions', '*.rb')].each { |file| require file }

require_relative 'lib/migration.rb'
# Dir[File.join(__dir__, 'lib', '*.rb')].each { |file| require file }

# https://guides.rubygems.org/make-your-own-gem/

module Tippfaul

  def self.base_dir
    return __dir__
  end

  def self.template_dir
    return File.join(__dir__, 'templates')
  end

  def self.license_hint
    return 'Licensed under GNU AGPL v3'
  end

  def self.base_package
    return package_slugs.join('.')
  end

  def self.package_slugs
    return ['de', 'andarte', 'recipes']
  end

  def self.project_root
    return Dir.pwd
  end

end

class TippfaulCLI < Thor
  class_option :verbose, :type => :boolean, :aliases => "-v"
  class_option :with_service, :type => :boolean, :aliases => "--ws", :default => false

  desc "generate THING PARAMETERS", "Generate migration / model"

  def generate(thing, *parameters)

    command = case thing
    when 'migration'
      puts "Create a new migration #{parameters}"
      MigrationCommand.new(parameters)

    when 'scaffold'
      puts "Create a new scaffold #{parameters}"
      ModelCommand.new(parameters)

    when 'liquibase'
      puts "Create from liquibase migration"
      FromLiquibaseCommand.new(parameters)

    else
      raise "Sorry, #{thing} is not supported yet."
    end

    command.exec!
  end

end

TippfaulCLI.start(ARGV)
