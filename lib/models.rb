require 'sqlite3'

DB = SQLite3::Database.open 'test.db'

DB.execute <<SQL
  CREATE TABLE IF NOT EXISTS questions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    data TEXT
  );
SQL

DB.execute <<SQL
  CREATE TABLE IF NOT EXISTS answers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    data TEXT,
    question_id INT,
    FOREIGN KEY (question_id) REFERENCES questions(id)
  );
SQL

class Query
  @@queries = []
  @@tables_executed = []
  @@sync_in_progress = false
  attr_reader :table, :model

  def initialize(table, model)
    @table = table
    @model = model
    @@queries << self
  end

  def self.unsynced_group_by_table
    unsynced_queries.group_by {|x| x.table }
  end

  def self.unsynced_queries
    @@queries.find_all{|x| !x.model.internal_synced}
  end

  def self.sync_table(table)
    queries = unsynced_group_by_table[table]
    DB.execute <<SQL
            INSERT INTO #{table} (#{queries[0].model.sql_attrs.keys.join(' ,')})
            VALUES
            #{queries.map{|x| "(#{x.model.sql_attrs.values.join(' ,')})"}.join(",\n")};      
SQL

    result  = DB.execute <<SQL
        SELECT id, #{queries[0].model.sql_attrs.keys.join(', ')}
        FROM #{table}
        ORDER BY ID DESC
        LIMIT #{queries.length};
SQL
    queries.each_with_index{|query, i|
      query.model.internal_received_attributes = Hash[[:id, query.model.sql_attrs.keys].flatten.map(&:to_sym).zip(result[result.length - 1 - i])]
      query.model.internal_synced = true
    }
  end

  def self.sync
    unsynced_group_by_table.each do |table, queries|
      sync_table table
    end
  end
end

class Model
  attr_accessor :internal_received_attributes, :internal_attributes, :internal_synced
  @internal_synced = false
  def sql_attrs
    # reserving variables with the name internal
    instance_variables
      .find_all{|x| !x.to_s.include?('internal')}
      .each_with_object({}) do |var, hash|
      hash[var.to_s.delete('@')] = instance_variable_get(var)
    end.merge(internal_attributes || {})
  end

  def save
    Query.new(table, self)
  end
end

class QuestionModel < Model
  attr_reader :data

  def initialize(data)
    @data = "'#{data}'"
  end

  # def create_answer(data)
  #   @internal_answers ||= []
  #   @internal_answers << AnswerModel()
  # end

  def id
    Query.sync_table(table) unless internal_synced
    internal_received_attributes[:id]
  end

  def table
    'questions'
  end
end

class AnswerModel < Model
  attr_reader :internal_parent, :data

  def initialize(question, data)
    @internal_parent = question
    @data = "'#{data}'"
  end

  def internal_attributes
    {question_id: @internal_parent.id }
  end

  def table
    'answers'
  end
end