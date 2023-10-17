class Page
  @@regex = / Respuestas:\s+(?:\s+- [\p{L} ,\d:%\.\/\(\)\-¿\? °;–"]+\.?\n{1,})+/
  def initialize(page)
    @text = page.text
  end

  def questions
    @questions ||= @text.split(@@regex)
  end

  def answers
    @answers ||= @text.scan(@@regex)
  end

  def q_a
    @q_a ||=  answers.map.with_index{|answer, index| [questions[index], answer]}.to_h
  end
end
