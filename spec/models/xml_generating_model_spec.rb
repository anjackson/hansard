
describe "an xml-generating model", :shared => true do
  
  it "should respond to activerecord_xml" do
    @model.respond_to?("to_activerecord_xml").should be_true
  end
  
  it "should respond to xml" do
    @model.respond_to?("to_xml").should be_true
  end
  
  it "should have different methods to_xml and activerecord_to_xml" do
    @model.to_xml.should_not eql(@model.to_activerecord_xml)
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