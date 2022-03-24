
class Renderer
  attr_reader :template

  def initialize(template_file)
    @template = File.open("#{template_file}.erb", 'rb', &:read)
  end

  def render(binding_scope)
    ERB.new(template).result(binding_scope)
  end
end
