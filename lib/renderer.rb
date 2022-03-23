
class Renderer
  attr_reader :template, :binding_klass

  def initialize(template_file, binding_klass)
    @template = File.open("#{template_file}.erb", 'rb', &:read)
    @binding_klass = binding_klass
  end

  def render
    ERB.new(template).result(binding_klass.binding)
  end
end
