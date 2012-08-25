def stub_model_methods
  Act.stub!(:populate_mentions).and_return([])
  Bill.stub!(:populate_mentions).and_return([])
  Constituency.stub!(:find_by_name_and_date)
  CommonsMembership.stub!(:find_from_contribution).and_return nil
  Contribution.stub!(:populate_memberships)
end

def parse_hansard file
  stub_model_methods
  parser = Hansard::CommonsParser.new(File.dirname(__FILE__) + "/../../data/#{file}")
  parser.stub!(:anchor_id)
  parser.parse
end

def parse_hansard_file parser_type, file, data_file=nil, source_file=nil
  stub_model_methods
  parser = parser_type.new(file, data_file, source_file)
  parser.stub!(:anchor_id)
  parser.parse
end

describe "All sittings or written answers or written statements", :shared => true do
  
  it 'should create a valid sitting' do
    @sitting.valid?.should be_true
  end

  it 'should create sitting with correct type' do
    @sitting.should_not be_nil
    @sitting.should be_an_instance_of(@sitting_type)
  end

  it 'should set sitting date' do
    @sitting.date.should == @sitting_date
  end

  it 'should set sitting date text' do
    @sitting.date_text.should == @sitting_date_text
  end

  it 'should set sitting title' do
    @sitting.title.should == @sitting_title
  end

  it 'should set the sitting chairman' do
    @sitting.chairman.should == @sitting_chairman
  end

  it 'should set start column of sitting' do
    @sitting.start_column.should == @sitting_start_column
  end

  it 'should set end column of sitting' do
    @sitting.end_column.should == @sitting_end_column
  end

end

describe "All sittings", :shared => true do

  it_should_behave_like "All sittings or written answers or written statements"

  it 'should create debates section' do
    @sitting.debates.should_not be_nil
    @sitting.debates.should be_an_instance_of(Debates)
  end
end

describe "All parsers", :shared => true do 

    
    it 'should respond to anchor_integer' do 
      @parser.respond_to?(:anchor_integer).should be_true
    end
    
    it 'should respond to anchor_integer=' do 
      @parser.respond_to?(:anchor_integer).should be_true
    end
    
    it 'should initialize the anchor_integer to 1' do 
      @parser.anchor_integer.should == 1
    end
    
    it 'should increment the anchor_integer by 1 when asked for an anchor_id' do 
      @parser.anchor_id
      @parser.anchor_integer.should == 2
    end  
end
