require File.dirname(__FILE__) + '/../spec_helper'

describe WestminsterHallController, " in general" do
  it_should_behave_like "All controllers"
end

describe WestminsterHallController, "#route_for" do

  before(:each) do
    @house_type = 'westminster_hall'
  end

  it_should_behave_like "controller that has routes correctly configured"
  it_should_behave_like "controller that isn't mapping the root url"

end

describe WestminsterHallController, " handling dates" do

  it_should_behave_like "a date-based controller"

end

describe WestminsterHallController, " handling GET /westminster_hall" do

  before(:all) do
    @sitting_model = WestminsterHallSitting
  end

  it_should_behave_like " handling GET /<house_type>"

end

describe WestminsterHallController, " handling GET /westminster_hall/1999" do

  before(:all) do
    @sitting_model = WestminsterHallSitting
  end

  it_should_behave_like " handling GET /<house_type>/1999"

end

describe WestminsterHallController, " handling GET /westminster_hall/1999/feb" do

  before(:all) do
    @sitting_model = WestminsterHallSitting
  end

  it_should_behave_like " handling GET /<house_type>/1999/feb"

end

describe WestminsterHallController, "handling GET /westminster_hall/1999/feb/08" do

  before(:all) do
    @sitting_model = WestminsterHallSitting
  end

  it_should_behave_like " handling GET /<house_type>/1999/feb/08"

end
