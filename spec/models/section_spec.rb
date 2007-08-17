require File.dirname(__FILE__) + '/../spec_helper'


describe Section, " in general" do
  
  before(:each) do
    @model = Section.new
    @mock_builder = mock("xml builder") 
    @mock_builder.stub!(:title)  
  end
    
  it_should_behave_like "an xml-generating model"

end

describe Section, ".to_xml" do
  
  before do
    @mock_builder = mock("xml builder")    
    @mock_builder.stub!(:title)
    @section = Section.new
  end
  
  it "should have one 'title' tag containing the title " do
    @section.title = "test title"
    @section.to_xml.should have_tag("title", :text => "test title", :count => 1)
  end
  
  it "should call the to_xml method on each of it's contributions, passing it's xml builder" do
    Builder::XmlMarkup.should_receive(:new).and_return(@mock_builder)
    first_contribution = mock_model(Contribution)
    second_contribution = mock_model(Contribution)
    @section.contributions << first_contribution
    @section.contributions << second_contribution
    first_contribution.should_receive(:to_xml).with(:builder => @mock_builder)
    second_contribution.should_receive(:to_xml).with(:builder => @mock_builder)
    @section.to_xml
  end
   
  it "should call the to_xml method on each of it's sections, passing it's xml builder" do
    Builder::XmlMarkup.should_receive(:new).and_return(@mock_builder)
    first_section = mock_model(Section)
    second_section = mock_model(Section)
    @section.sections << first_section
    @section.sections << second_section
    first_section.should_receive(:to_xml).with(:builder => @mock_builder)
    second_section.should_receive(:to_xml).with(:builder => @mock_builder)
    @section.to_xml
  end
  
end
