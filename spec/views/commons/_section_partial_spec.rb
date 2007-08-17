require File.dirname(__FILE__) + '/../../spec_helper'

describe "_section partial", "when passed prayers section" do

  before do
    @title = 'PRAYERS'

    @prayers = mock_model(Section)

    @prayers.stub!(:title).and_return(@title)
    @prayers.stub!(:contributions).and_return([])

    @controller.template.stub!(:section).and_return(@prayers)

    render 'commons/_section.haml'
  end

  it 'should show prayers as p with class procedural' do
    response.should have_tag('h2', @title)
  end

end
