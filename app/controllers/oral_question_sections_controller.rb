class OralQuestionSectionsController < ApplicationController
  
  def show
    @oral_question_section = OralQuestionSection.find(params[:id])
    respond_to do |format|
      format.html
      format.xml { render :xml => @oral_question_section.to_xml }
    end
  end
  
end