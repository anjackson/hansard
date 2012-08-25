describe "a mentionable model when populating mentions", :shared => true do 
  
  it 'should create a resolver for the text of the contribution' do 
    @mock_resolver_class.should_receive(:new).and_return(@mock_resolver)
    @mentionable_class.populate_mentions(@contribution.text, @contribution.section, @contibution)
  end
  
  it 'should get the mentions from the resolver' do
    @mock_resolver.should_receive(:mention_attributes).and_return([])
    @contribution.populate_mentions
  end

  it 'should find or create a model from the attributes of each mention' do 
    @mock_resolver.stub!(:mention_attributes).and_return([{:name => "name",
                                                           :start_position => 0,
                                                           :end_position => 10}])
    @mentionable_class.should_receive(:find_or_create_from_resolved_attributes)
    @mentionable_class.populate_mentions("test text", @section, @contribution)
  end
  
  it 'should create a mention for each reference' do 
    @mock_resolver.stub!(:mention_attributes).and_return([{:name => "name",
                                                           :start_position => 0,
                                                           :end_position => 10}])
    @mention_class.should_receive(:new).and_return(mock_model(@mention_class))
    @mentionable_class.populate_mentions("test text", @section, @contribution)
  end
  
  it 'should set the contribution, section, sitting, start position, end position and date on the new mention' do 
    @mock_resolver.stub!(:mention_attributes).and_return([{:name => "name",
                                                           :start_position => 0,
                                                           :end_position => 10}])
    @mentionable = mock_model(@mentionable_class)
    @mentionable_class.stub!(:find_or_create_from_resolved_attributes).and_return(@mentionable)
    @mention_class.should_receive(:new).with(@mentionable_class.name.downcase.to_sym => @mentionable, 
                                              :start_position => 0, 
                                              :end_position => 10, 
                                              :date => @section.sitting.date, 
                                              :sitting => @section.sitting,
                                              :section => @section, 
                                              :contribution => @contribution)     
     @mentionable_class.populate_mentions("test text", @section, @contribution)                                                                                           
  end
  
  it 'should not do anything if the contribution doesn\'t have any text' do 
    @mention_class.should_not_receive(:new)
    @mentionable_class.populate_mentions(nil, @section, @contribution)
  end
  
end