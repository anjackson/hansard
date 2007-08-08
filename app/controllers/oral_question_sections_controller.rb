class OralQuestionSectionsController < ApplicationController
  
  def show
    @oral_question_section = OralQuestionSection.find(params[:id])
  end
  
end