describe "a contribution", :shared => true do
  
  it "should return one 'p' tag with the id attribute set to the xml_id of the contribution if it has one" do
    @contribution.xml_id = "testid"
    @contribution.to_xml.should have_tag('p[id=testid]', :count => 1)
  end

  it "should return a 'p' tag with no id attribute if the contribution does not have an xml_id" do
    @contribution.to_xml.should have_tag('p', :count => 1)
    @contribution.to_xml.should_not have_tag('p[id]')
  end
  
  it "should render it's text if there is any" do
    @contribution.text = "some text"
    @contribution.to_xml.should match(/some text/)
  end
  
  it "should have a 'p' tag with any style information for the contribution set as tag attributes" do
    @contribution.xml_id = "xmlid"
    @contribution.style = "align=center"
    @contribution.to_xml.should have_tag("p#xmlid[align=center]")    
  end

end