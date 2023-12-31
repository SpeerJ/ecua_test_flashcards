require 'pdf-reader'
require 'anki2'
require_relative 'page'
require_relative 'models'

#@anki = Anki2.new

# Specify the path to your PDF file
pdf_path = '/home/johann/RubymineProjects/ecua_doc_flashcards/banco.pdf'

# Create a PDF reader object
pdf_reader = PDF::Reader.new(pdf_path)

# Iterate through each page in the PDF and extract text
pdf_reader.pages.each_with_index do |page, index|
  next if index < 2
  p = Page.new(page)

  next if p.q_a.empty?
  p.q_a.each do |k, v|
    q = QuestionModel.new(k)
    q.save
    AnswerModel.new(q, v).save
  end
end
Query.sync()
#@anki.save
