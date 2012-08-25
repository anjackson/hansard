
describe "an xml-generating model", :shared => true do
  
  it "should respond to xml" do
    @model.respond_to?("to_xml").should be_true
  end
  
  it "should respond to to_activerecord_xml" do
    @model.respond_to?("to_activerecord_xml").should be_true
  end

  it "should produce some output from it's to_xml method" do
    @model.to_xml.should_not be_nil
  end
  
  it "should create an xml builder in it's to_xml method if it is not passed one in the options hash" do
    Builder::XmlMarkup.should_receive(:new).and_return(@mock_builder)
    @model.to_xml
  end
  
  it "should not create an xml builder if one is passed to it's to_xml method in the :builder param of the options hash" do
    Builder::XmlMarkup.should_not_receive(:new)
    @model.to_xml(:builder => @mock_builder)
  end

end


describe "a section to_xml method", :shared => true do
  
  it "should call the to_xml method on each of it's contributions, passing it's xml builder" do
    Builder::XmlMarkup.should_receive(:new).and_return(@mock_builder)
    first_contribution = mock_model(@contribution_class)
    second_contribution = mock_model(@contribution_class)
    [first_contribution, second_contribution].each do |contribution|
      @section.contributions << contribution
      contribution.stub!(:cols).and_return([])
      contribution.stub!(:different_image).and_return(false)
      contribution.should_receive(:to_xml).with(:builder => @mock_builder)
    end
    @section.to_xml
  end
   
  it "should call the to_xml method on each of it's sections, passing it's xml builder" do
    Builder::XmlMarkup.should_receive(:new).and_return(@mock_builder)
    if @subsection_class
      first_section = mock_model(@subsection_class)
      second_section = mock_model(@subsection_class)
      [first_section, second_section].each do |section|
        @section.sections << section
        section.stub!(:start_column)
        section.should_receive(:to_xml).with(:builder => @mock_builder)
      end
    end
 
    @section.to_xml
  end
  
end
