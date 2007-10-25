require File.dirname(__FILE__) + '/house_controller_spec_helper'

describe SittingsController, "#route_for" do

  before(:each) do
    @house_type = 'written_answers'
  end

  it_should_behave_like "controller that has routes correctly configured"

end

describe SittingsController, " handling dates" do

  it_should_behave_like "a date-based controller"

end

describe SittingsController, " handling GET /sittings" do

  before(:all) do
    @sitting_model = Sitting
  end

  it_should_behave_like " handling GET /<house_type>"
  
end

describe SittingsController, " handling GET /sittings/1999" do

  before(:all) do
    @sitting_model = Sitting
  end

  it_should_behave_like " handling GET /<house_type>/1999"

end

describe SittingsController, " handling GET /sittings/1999/feb" do

  before(:all) do
    @sitting_model = Sitting
  end

  it_should_behave_like " handling GET /<house_type>/1999/feb"

end

describe SittingsController, "handling GET /sittings/1999/feb/08" do

  before(:all) do
    @sitting_model = Sitting
  end

  it_should_behave_like " handling GET /<house_type>/1999/feb/08"
  
end


describe SittingsController, " handling GET /sittings/source/1999/feb/08.xml" do

  before(:all) do
    @sitting_model = Sitting
  end

  it_should_behave_like " handling GET /<house_type>/source/1999/feb/08.xml"

end

