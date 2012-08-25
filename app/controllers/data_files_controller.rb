class DataFilesController < ApplicationController

  include Hansard::ParserTaskHelper

  def index
    @data_files = DataFile.find(:all)
  end

  def show_warnings
    @data_files = DataFile.find(:all).select{ |f| f.log? }.sort_by(&:name).group_by(&:saved)
  end

  def reload_written_answers_for_date
    reload_file {|date| reload_written_answers_on_date(date) }
  end
  
  def reload_written_statements_for_date
    reload_file {|date| reload_written_statements_on_date(date) }
  end

  def reload_lords_for_date
    reload_file {|date| reload_lords_on_date(date) }
  end

  def reload_commons_for_date
    reload_file {|date| reload_commons_on_date(date) }
  end

  protected

    def reload_file
      if request.post?
        if DataFile.reload_possible?
          date = Date.parse(params['date'])
          data_file = yield date
          @data_file = DataFile.find(data_file.id)
        else
          render :text => ''
        end
      else
        render :text => ''
      end
    end
end