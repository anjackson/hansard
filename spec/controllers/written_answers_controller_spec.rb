require File.dirname(__FILE__) + '/../spec_helper'

describe WrittenAnswersController, " in general" do
  it_should_behave_like "All controllers"
end

describe WrittenAnswersController, "#route_for" do

  before(:each) do
    @house_type = 'written_answers'
  end

  it_should_behave_like "controller that has routes correctly configured"
  it_should_behave_like "controller that isn't mapping the root url"

end

describe WrittenAnswersController, " handling dates" do

  it_should_behave_like "a date-based controller"

end

describe WrittenAnswersController, " handling GET /writtenanswers" do

  before(:all) do
    @sitting_model = WrittenAnswersSitting
  end

  it_should_behave_like " handling GET /<house_type>"

end

describe WrittenAnswersController, " handling GET /writtenanswers/1999" do

  before(:all) do
    @sitting_model = WrittenAnswersSitting
  end

  it_should_behave_like " handling GET /<house_type>/1999"

end

describe WrittenAnswersController, " handling GET /writtenanswers/1999/feb" do

  before(:all) do
    @sitting_model = WrittenAnswersSitting
  end

  it_should_behave_like " handling GET /<house_type>/1999/feb"

end

describe WrittenAnswersController, "handling GET /writtenanswers/1999/feb/08" do

  before(:all) do
    @sitting_model = WrittenAnswersSitting
  end

  it_should_behave_like " handling GET /<house_type>/1999/feb/08"

end
