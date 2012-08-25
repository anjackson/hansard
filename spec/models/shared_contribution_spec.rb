describe "a contribution", :shared => true do
  
  it "should return one 'p' tag with the id attribute set to the anchor_id of the contribution" do
    @contribution.anchor_id = "testid"
    @contribution.to_xml.should have_tag('p[id=testid]', :count => 1)
  end

  it "should render it's text if there is any" do
    @contribution.text = "some text"
    @contribution.to_xml.should match(/some text/)
  end
  
  it "should have a 'p' tag with any style information for the contribution set as tag attributes" do
    @contribution.anchor_id = "anchorid"
    @contribution.style = "align=center"
    @contribution.to_xml.should have_tag("p#anchorid[align=center]")    
  end

end