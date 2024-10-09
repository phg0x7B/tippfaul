
class ServiceCommand
  attr_reader :arguments

  def initialize(arguments)
    @service_name = arguments.shift
    @arguments = arguments
  end

  def process_arguemnts

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

    open_target(File.join(Tippfaul.base_dir, '..', 'src', 'main', 'java', Tippfaul.package_slugs, 'model' "#{@service_name}Service.java")) do |out|
        out.puts Renderer.new(File.join(Tippfaul.template_dir, "service.java.erb")).render(binding)
    end
    open_target(File.join(Tippfaul.base_dir, '..', 'src', 'main', 'java', Tippfaul.package_slugs, 'model' "#{@service_name}ServiceImpl.java")) do |out|
        out.puts Renderer.new(File.join(Tippfaul.template_dir, "service-impl.java.erb")).render(binding)
    end
  end
end
