class RenameOralQuestionNo < ActiveRecord::Migration
  def self.up
    rename_column :contributions, :oral_question_no, :question_no
  end

  def self.down
    rename_column :contributions, :question_no, :oral_question_no
  end
end
