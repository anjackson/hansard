require File.dirname(__FILE__) + '/section_spec_helper'

describe WrittenStatementsBody do
  
  before do 
    @model = WrittenStatementsBody
  end
  
  it_should_behave_like "a body model for a written sitting"

end
