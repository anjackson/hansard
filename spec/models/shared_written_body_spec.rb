describe "a body model for a written sitting", :shared => true do
  
  describe 'when asked for id_hash' do
    it "should return parent section's id_hash" do
      body = @model.new
      id_hash = mock('id_hash')
      body.should_receive(:parent_section).and_return mock('parent_section', :id_hash=>id_hash)
      body.id_hash.should == id_hash
    end
  end

  describe 'when asked if it is a written body' do 
  
    it 'should return true' do 
      section = @model.new
      section.is_written_body?.should be_true
    end
  
  end
end