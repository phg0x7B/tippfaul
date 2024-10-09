
module Pluralize

  IRREGULAR_WORDS_SINGULAR = {
    'woman': 'women',
    'man': 'men',
    'child': 'children',
    'tooth': 'teeth',
    'class': 'classes'
  }.freeze


  IRREGULAR_WORDS_PLURAL = IRREGULAR_WORDS_SINGULAR.invert

  def pluralize
    if IRREGULAR_WORDS_SINGULAR[self.downcase]
      IRREGULAR_WORDS_SINGULAR[self.downcase]
    elsif self.end_with?('s')
      self
    else
      self + 's'
    end
  end

  def singular
    if IRREGULAR_WORDS_PLURAL[self.downcase]
      IRREGULAR_WORDS_PLURAL[self.downcase]
    elsif self.end_with?('s')
      self[0,self.length - 1]
    else
      self
    end
  end
end

class String
  include ::Pluralize
end
