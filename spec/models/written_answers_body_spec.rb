require File.dirname(__FILE__) + '/section_spec_helper'

describe WrittenAnswersBody do
  
  before do 
    @model = WrittenAnswersBody
  end
  
  it_should_behave_like "a body model for a written sitting"
  
end
