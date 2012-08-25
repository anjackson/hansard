require File.dirname(__FILE__) + '/../spec_helper'

def mock_commons_sitting
  sitting = HouseOfCommonsSitting.new(
                        :start_column    => "1",
                        :end_column      => '1',
                        :date            => Date.new(1985, 12, 16),
                        :date_text       => "Monday 16th December 1985")
  sitting.debates = Debates.new
  sitting
end

def mock_housecommons_builder
  mock_builder = mock("xml builder")
  mock_builder.stub!(:housecommons).and_yield
  [:image, :col, :title, :date, :<<, :debates].each { |field| mock_builder.stub!(field) }
  mock_builder
end

describe HouseOfCommonsSitting, 'creating hansard reference' do
  before do
    @sitting = mock_commons_sitting
    volume = mock_model(Volume, :number => 5)
    @sitting.stub!(:volume).and_return volume
  end

  it 'should create reference correctly when there is no end_column' do
    @sitting.hansard_reference(1, nil).should == 'HC Deb 16 December 1985 vol 5 c1'
  end
  
  it 'should create reference correctly start and end column is zero ' do
    @sitting.hansard_reference(0, 0).should == 'HC Deb 16 December 1985 vol 5'
  end

  it 'should create reference correctly when end column same as start column' do
    @sitting.hansard_reference(1, 1).should == 'HC Deb 16 December 1985 vol 5 c1'
  end

  it 'should create reference correctly when end column differs from start column' do
    @sitting.hansard_reference(1, 4).should == 'HC Deb 16 December 1985 vol 5 cc1-4'
  end

  it 'should create reference correctly when end column differs from start column by one significant digit' do
    @sitting.hansard_reference(390, 391).should == 'HC Deb 16 December 1985 vol 5 cc390-1'
  end

  it 'should create reference correctly when end column differs from start column by two significant digits' do
    @sitting.hansard_reference(416, 421).should == 'HC Deb 16 December 1985 vol 5 cc416-21'
  end

  it 'should create reference correctly when end column differs from start column by three significant digits' do
    @sitting.hansard_reference(496, 501).should == 'HC Deb 16 December 1985 vol 5 cc496-501'
  end

  it 'should create reference correctly when end column differs from start column by four significant digits' do
    @sitting.hansard_reference(996, 1001).should == 'HC Deb 16 December 1985 vol 5 cc996-1001'
  end
end

describe HouseOfCommonsSitting, ', the class' do
  it 'should respond to find_by_date' do
    lambda {HouseOfCommonsSitting.find_by_date('1999-02-08')}.should_not raise_error
  end

  it 'should have uri_component equal to "commons"' do
    HouseOfCommonsSitting.uri_component.should == 'commons'
  end

  it 'should have house equal to "Commons"' do
    HouseOfCommonsSitting.house.should == 'Commons'
  end
end

describe HouseOfCommonsSitting, 'an instance' do

  before do
    @sitting = HouseOfCommonsSitting.new :date => '2007-12-12'
    @debates = Debates.new
    @sitting.debates = @debates
  end

  it 'should have debates' do
    @sitting.debates.should_not be_nil
    @sitting.debates.should be_an_instance_of(Debates)
  end

  it 'should have uri_component equal to "commons"' do
    @sitting.uri_component.should == 'commons'
  end

end

describe HouseOfCommonsSitting do

  before(:each) do
    @model = mock_commons_sitting
    @mock_builder = mock_housecommons_builder
  end

  it "should be valid" do
    @model.should be_valid
  end

  it_should_behave_like "an xml-generating model"

end

describe HouseOfCommonsSitting, ".to_xml" do

  before do
    @mock_builder = mock_housecommons_builder
    @sitting = mock_commons_sitting
  end

  it "should have a 'housecommons' tag" do
    @sitting.to_xml.should match(/<housecommons>.*?<\/housecommons>/m)
  end

  it "should have a 'col' tag containing the sitting's start column" do
    @sitting.to_xml.should match(/<col>1<\/col>/)
  end

  it "should have a 'title' tag containing the sitting title" do
    @sitting.title = "test title"
    @sitting.to_xml.should match(/<title>#{@sitting.title}<\/title>/)
  end

  it "should have a 'date' tag with a format attribute containing the sitting date in yyyy-mm-dd format, containing the sitting date text" do
    @sitting.to_xml.should match(/<date format="1985-12-16">Monday 16th December 1985<\/date>/)
  end
  
  it "should call the to_xml method on each of it's debates, passing it's xml builder" do
    Builder::XmlMarkup.should_receive(:new).and_return(@mock_builder)
    debates = mock_model(Debates)
    @sitting.debates = debates
    debates.should_receive(:to_xml).with(:builder => @mock_builder, :current_column => '1')
    @sitting.to_xml
  end

end

describe HouseOfCommonsSitting, " destroy" do

  it 'should destroy child debates, oral questions, sections, contributions, divisions and votes' do
    Section.delete_all
    Contribution.delete_all
    Division.delete_all
    Vote.delete_all
    Sitting.delete_all
    Contribution.stub!(:populate_memberships)
    
    sitting = HouseOfCommonsSitting.new
    sitting.debates = Debates.new(:sitting => sitting)

    sitting.debates.sections << Section.new(:title=>'PRIVATE BUSINESS', :sitting => sitting)
    sitting.debates.sections[0].sections << Section.new(:title=>'ANGLE ORE AND TRANSPORT COMPANY BILL [Lords]', :sitting => sitting)
    sitting.debates.sections[0].sections[0].contributions << ProceduralContribution.new(:text=>"<i>Queen's Consent, on behalf of the Crown, signified.</i>", :section => sitting.debates.sections[0].sections[0])

    sitting.debates.sections << OralQuestions.new(:title => 'ORAL ANSWERS TO QUESTIONS', :sitting => sitting)
    sitting.debates.sections[1].sections << OralQuestionsSection.new(:title => 'GOVERNMENT INFORMATION SERVICES', :sitting => sitting)
    sitting.debates.sections[1].sections[0].questions << OralQuestionSection.new(:title => 'Television Films', :sitting => sitting)
    sitting.debates.sections[1].sections[0].questions[0].contributions << MemberContribution.new(:question_no=>1, :xml_id=>"S5CV0602P0-00252", :member_name=>"Mr. John Hall", :text=>"<p>asked the Chancellor of the Duchy of Lancaster what steps he has taken to ensure that an adequate supply of suitable British filmed material is available to countries starting television services.</p>", :section => sitting.debates.sections[1].sections[0].questions[0])

    sitting.debates.sections << Section.new(:title => 'ANGLO-EGYPTIAN FINANCIAL AGREEMENT', :sitting => sitting)
    member_contribution = MemberContribution.new(:xml_id=>"S5CV0602P0-00641", :member_name=>"Mr. George Chetwynd", :member_suffix =>"(Stockton-on-Tees)", :text => 'For the right hon. Gentleman, yes.', :section => sitting.debates.sections[2])
    member_contribution.stub!(:populate_constituency)
    sitting.debates.sections[2].contributions << member_contribution
    sitting.debates.sections[2].contributions << DivisionPlaceholder.new
    sitting.debates.sections[2].contributions[1].division = Division.new(:name=>'Division No. 65.]',:time_text=>'10.00 p.m.')
    sitting.debates.sections[2].contributions[1].division.votes << AyeVote.new(:name=>'Agnew, Sir Peter')
    sitting.debates.sections[2].contributions[1].division.votes << NoeVote.new(:name=>'Abse, Leo')

    CommonsMembership.stub!(:find_from_contribution)

    sitting.stub!(:date).and_return(Date.new(2004, 12, 1))

    sitting.save!

    Sitting.find(:all).size.should == 1
    Section.find(:all).size.should == 7
    Contribution.find(:all).size.should == 4
    Division.find(:all).size.should == 1
    Vote.find(:all).size.should == 2

    sitting.destroy

    Sitting.find(:all).size.should == 0
    Section.find(:all).size.should == 0
    Contribution.find(:all).size.should == 0
    Division.find(:all).size.should == 0
    Vote.find(:all).size.should == 0
  end

  after(:all) do
    Sitting.find(:all).each {|s| s.destroy}
  end
end

describe HouseOfCommonsSitting, 'when finding section by column and date' do
  it 'should return correct section' do
    date = Date.new(2006,1,1)
    sitting = HouseOfCommonsSitting.create(:date => date, :start_column => '44', :end_column => '50')
    section = Section.new(:start_column => '44', :end_column => '47')
    sitting.all_sections << section
    sitting.save!
    HouseOfCommonsSitting.find_section_by_column_and_date('44', date).should == section
  end

  def setup_some_sections
    @date = Date.new(2006,1,1)
    sitting = HouseOfCommonsSitting.create(:date => @date, :start_column => '44', :end_column => '50')
    section = Section.new(:start_column => '44', :end_column => '47')

    @sub_section1 = Section.new(:start_column => '44', :end_column => '45')
    @sub_section2 = Section.new(:start_column => '45', :end_column => '45')
    @sub_section3 = Section.new(:start_column => '45', :end_column => '47')

    @sub_section1.stub!(:create_slug)
    @sub_section2.stub!(:create_slug)
    @sub_section3.stub!(:create_slug)
    section.sections = [@sub_section1, @sub_section2, @sub_section3]

    sitting.all_sections << section
    sitting.save!
  end

  it 'should return most specific sub-section possible when only start column specified' do
    setup_some_sections
    HouseOfCommonsSitting.find_section_by_column_and_date('44', @date).should == @sub_section1
    HouseOfCommonsSitting.find_section_by_column_and_date('45', @date).should == @sub_section1
    HouseOfCommonsSitting.find_section_by_column_and_date('46', @date).should == @sub_section3
    HouseOfCommonsSitting.find_section_by_column_and_date('47', @date).should == @sub_section3
  end

  it 'should return most specific sub-section when start and end column specified match start and end column of a section' do
    setup_some_sections
    HouseOfCommonsSitting.find_section_by_column_and_date('44', @date, '45').should == @sub_section1
  end

  it 'should return most specific sub-section when start column specified matches a section start column, and end column specified is before that sections end column' do
    setup_some_sections
    HouseOfCommonsSitting.find_section_by_column_and_date('45', @date, '46').should == @sub_section3
  end

  it 'should return most specific sub-section when start column specified is after a sections start column and end column specified matches that sections end column' do
    setup_some_sections
    HouseOfCommonsSitting.find_section_by_column_and_date('46', @date, '47').should == @sub_section3
  end

  it 'should return most specific sub-section when start column specified is before a sections end column and end column specified is after that sections end but there are no sections following that section' do
    setup_some_sections
    HouseOfCommonsSitting.find_section_by_column_and_date('47', @date, '48').should == @sub_section3
  end

  it 'should write an error to the log and return nil if more than one sitting is found' do
    HouseOfCommonsSitting.stub!(:find_all_by_date).and_return([Sitting.new, Sitting.new])
    HouseOfCommonsSitting.logger.should_receive(:error).with("Error: Sitting.find_section_by_column_and_date unexpectedly found more than one HouseOfCommonsSitting sitting for date ")
    HouseOfCommonsSitting.find_section_by_column_and_date('47', @date, '48').should be_nil
  end

  after do
    Sitting.delete_all
    Section.delete_all
  end
end

describe HouseOfCommonsSitting, '.sitting_type_name' do

  it 'should be Commons' do
    HouseOfCommonsSitting.new.sitting_type_name.should == 'Commons'
  end

end

describe HouseOfCommonsSitting, ".top_level_sections" do

  it "should return the sub-sections of the debates section" do
    sitting = HouseOfCommonsSitting.new
    debates = Debates.new
    sitting.debates = debates
    section = Section.new
    sitting.debates.sections << section
    sitting.top_level_sections.should == [section]
  end
end
