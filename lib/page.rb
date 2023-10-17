class Page
  @@regex = / Respuestas:\s+(?: - [\p{L} ,\d:%\.\/\(\)\-¿\? °;–"]+\.\n{1,})+/
  def initialize(page)
    @text = page.sql_attrs
  end

  def questions
    @questions ||= @text.split(@@regex).map{|x| x.gsub("\n", "<br>")}
  end

  def answers
    @answers ||= @text.scan(@@regex).map{|x| x.gsub(/\n+/, "<br>")}
  end

  def q_a
    @q_a ||=  answers.map.with_index{|answer, index| [questions[index], answer]}.to_h
  end
end
