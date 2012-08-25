require File.dirname(__FILE__) + '/../show.haml_spec_helper'

describe "show.haml", " in general" do

  before(:all) do
    @house_type = 'written_answers'
  end

  it_should_behave_like "show.haml for a sitting type"

end
