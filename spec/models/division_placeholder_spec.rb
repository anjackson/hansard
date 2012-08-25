require File.dirname(__FILE__) + '/../spec_helper'

def mock_divisions_placeholder_builder
  mock_builder = mock("xml builder")
  mock_builder
end

describe DivisionPlaceholder, "when asked for its xml id" do 

  it 'should not throw an error if it does not have a preceding contribution' do 
    placeholder = DivisionPlaceholder.new(:section => mock_model(Section, :preceding_contribution => nil))
    lambda{ placeholder.xml_id }.should_not raise_error
  end
  
end

describe DivisionPlaceholder, ".to_xml" do

  before do
    @division_placeholder = DivisionPlaceholder.new
  end

  it "should ask it's division for xml" do
    @division = Division.new
    @division_placeholder.division = @division
    @division.should_receive(:to_xml)
    @division_placeholder.to_xml
  end

  it 'should not throw an error if it does not have a division' do 
    lambda{ @division_placeholder.to_xml }.should_not raise_error
  end
  
end

describe DivisionPlaceholder, 'with division' do
  def make_placeholder mock_division
    @placeholder = DivisionPlaceholder.new
    @placeholder.stub!(:division).and_return mock_division
  end

  it 'should return count of votes in division' do
    make_placeholder mock_model(Division, :vote_count => 5)
    @placeholder.vote_count.should == 5
  end

  it 'should return whether division is complete compared to divided text' do
    make_placeholder mock_model(Division, :have_a_complete_division? => true)
    @placeholder.have_a_complete_division?("The House divided: Ayes, 235; Noes, 118.").should be_true
  end

  it 'should return division_id from division' do
    division_id = 'division_123'
    make_placeholder mock_model(Division, :division_id => division_id)
    @placeholder.division_id.should == division_id
  end

  it 'should set division name on division' do
    name = mock('name')
    division = mock('division')
    division.should_receive(:name=).with(name)
    make_placeholder division
    @placeholder.division_name = name
  end
end

describe DivisionPlaceholder, 'when in clause sub-section of a section' do

  before do
    @parent_section_title = 'title'
    @clause_section_title = 'clause'

    @parent_section = mock_model(Section, :title =>  @parent_section_title)
    @clause_section = mock_model(Section, :title => @clause_section_title, :parent_section => @parent_section, :is_clause? => true)
    @division = DivisionPlaceholder.new
    @division.stub!(:section).and_return @clause_section
  end

  it 'should return parent section title as the division section_title' do
    @division.section_title.should == @parent_section_title
  end

  it 'should return clause section title as the division sub_section_title' do
    @division.sub_section_title.should == @clause_section_title
  end

  it 'should return parent section as the section_for_division' do
    @division.section_for_division.should == @parent_section
  end

  it 'should return clause section as the division sub_section' do
    @division.sub_section.should == @clause_section
  end
end

describe DivisionPlaceholder, 'when in clause sub-section without a parent section' do

  before do
    @clause_section_title = 'clause'
    @clause_section = mock_model(Section, :title => @clause_section_title, :parent_section => nil, :is_clause? => true)
    @division = DivisionPlaceholder.new
    @division.stub!(:section).and_return @clause_section
  end

  it 'should return clause section title as the division section_title' do
    @division.section_title.should == @clause_section_title
  end

  it 'should return nil as the division sub_section_title' do
    @division.sub_section_title.should == nil
  end

  it 'should return clause section as the section_for_division' do
    @division.section_for_division.should == @clause_section
  end

  it 'should return nil as the division sub_section' do
    @division.sub_section.should == nil
  end

end

describe DivisionPlaceholder, 'when in clause sub-section of a section with a parent without a title' do

  before do
    @parent_section_title = nil
    @clause_section_title = 'clause'
    @parent_section = mock_model(Section, :title =>  @parent_section_title)
    @clause_section = mock_model(Section, :title => @clause_section_title, :parent_section => @parent_section, :is_clause? => true)
    @division = DivisionPlaceholder.new
    @division.stub!(:section).and_return @clause_section
  end

  it 'should return the clause section title as the division section_title' do
    @division.section_title.should == @clause_section_title
  end

  it 'should return nil as the division sub_section_title' do
    @division.sub_section_title.should == nil
  end

  it 'should return clause section as the section_for_division' do
    @division.section_for_division.should == @clause_section
  end

  it 'should return nil as the division sub_section' do
    @division.sub_section.should == nil
  end
  
end

describe DivisionPlaceholder, 'when validating' do

  it 'should not populate Act or Bill mentions' do
    contribution = DivisionPlaceholder.new(:section => Section.new(:sitting => Sitting.new))
    Act.should_not_receive(:populate_mentions)
    Bill.should_not_receive(:populate_mentions)
    contribution.valid?
  end
end

describe DivisionPlaceholder, 'when finding divided text' do
  it 'should take text of preceding contribution' do
    placeholder = DivisionPlaceholder.new

    divided_text = 'house divided'
    divided = mock(Contribution, :plain_text=>divided_text)
    placeholder.stub!(:preceding_contribution).and_return divided
    placeholder.divided_text.should == divided_text
  end
end

describe DivisionPlaceholder, 'when finding result text' do
  it 'should take text of following contribution, if it is recognized as result text' do
    placeholder = DivisionPlaceholder.new

    result_text = 'Question accordingly negatived'
    result = mock(Contribution, :plain_text=>result_text)
    placeholder.stub!(:following_contribution).and_return result

    Division.should_receive(:is_a_division_result?).with(result_text).and_return true
    placeholder.result_text.should == result_text
  end
end

describe DivisionPlaceholder, ' when calculating its index letter' do 

  it 'should set the index letter to "B" for a placeholder with section title "[BILL 18.] THIRD READING."' do 
    placeholder = DivisionPlaceholder.new
    placeholder.stub!(:section_title).and_return("[BILL 18.] THIRD READING.")
    placeholder.calculate_index_letter.should == 'B'
  end
  
end
