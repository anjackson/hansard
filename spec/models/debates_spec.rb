require File.dirname(__FILE__) + '/../spec_helper'

def mock_debates_builder
  mock_builder = mock("xml builder")   
  mock_builder.stub!(:debates).and_yield
  mock_builder
end

describe Debates, " in general" do
  
  before(:each) do
    @model = Debates.new
    @mock_builder = mock_debates_builder 
  end
  
  it_should_behave_like "an xml-generating model"

end

describe Debates, ".to_xml" do
  
  before do
    @mock_builder = mock_debates_builder 
    @debates = Debates.new
  end
  
  it "should have a 'debates' tag as it's outer element" do
    @debates.to_xml.should match(/^<debates>.*?<\/debates>$/)
  end
  
  it "should call the to_xml method on each of it's sections, passing it's xml builder" do
    Builder::XmlMarkup.should_receive(:new).and_return(@mock_builder)
    first_section = mock_model(Section)
    second_section = mock_model(Section)
    @debates.sections << first_section
    @debates.sections << second_section
    first_section.should_receive(:to_xml).with(:builder => @mock_builder)
    second_section.should_receive(:to_xml).with(:builder => @mock_builder)
    @debates.to_xml
  end
  
end

