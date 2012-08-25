require File.dirname(__FILE__) + '/../spec_helper'

describe Act do 

  describe "when asked for name and year" do
    
    it 'should return "Abdication Act" for Act with title "Abdication Act" and nil year' do
      act = Act.new(:name => "Abdication Act")
      act.name_and_year.should == "Abdication Act"
    end

    it 'should return "Access to Health Records Act 1990" for Act with title "Access to Health Records Act" and year 1990' do
      act = Act.new(:name => "Access to Health Records Act", :year => 1990)
      act.name_and_year.should == "Access to Health Records Act 1990"
    end

  end

  describe "finding or creating from resolved attributes" do 

    it 'should change the case of an existing match to titlecase if it is uppercase' do
      act = mock_model(Act, :name => 'TITLE')
      Act.stub!(:find_by_name_and_year).and_return(act)
      act.should_receive(:name=).with("Title")
      act.should_receive(:save)
      Act.find_or_create_from_resolved_attributes(:name => "Title", :year => 1974).should == act
    end
  
  end

  describe 'in general' do

    it 'should have id_hash mapping name to slug' do
      act = Act.new(:name => "Abdication Act")
      act.stub!(:slug).and_return "abdication_act"
      act.id_hash.should == {:name => "abdication_act"}
    end

  end


  describe " find_by_name_and_year" do

    it 'should ignore case when finding' do
      Act.should_receive(:find).with(:first, :conditions => ["LOWER(name) = ? and year = ?", 'title', 1974])
      Act.find_by_name_and_year("TITLE", 1974)
    end

  end

  describe " when populating mentions" do

    before do
      @mentionable_class = Act
      @contribution = Contribution.new(:text => "test text")
      @section = mock_model(Section, :parent_sections => [],
                                     :linkable? => true,
                                     :sitting => mock_model(Sitting, :date => Date.new(1923, 5, 4)))
      @contribution.stub!(:section).and_return(@section)
      @mock_resolver = mock("resolver", :mention_attributes => [])
      @mock_resolver_class = mock("resolver_class", :new => @mock_resolver)
      Act.stub!(:resolver).and_return(@mock_resolver_class)
      @mention_class = ActMention
    end

    it_should_behave_like "a mentionable model when populating mentions"

  end
  
  describe 'when finding others with the same name' do 
    
    it 'should ask for acts with the same name but a different id' do 
      act = Act.new(:name => 'test name')
      Act.should_receive(:find_all_by_name).with('test name', :conditions => ['id != ?', act.id])
      act.others_by_name
    end
    
  end
  
end