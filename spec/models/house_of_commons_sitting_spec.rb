require File.dirname(__FILE__) + '/../spec_helper'

def mock_sitting
  sitting = HouseOfCommonsSitting.new(:start_image_src => "source",
                        :start_column    => "1",
                        :date            => Date.new(1985, 12, 16),
                        :date_text       => "Monday 16th December 1985",
                        :text            => "some text")
  sitting.debates = Debates.new
  sitting
end

def mock_housecommons_builder
  mock_builder = mock("xml builder")
  mock_builder.stub!(:housecommons).and_yield
  [:image, :col, :title, :date, :<<, :debates].each { |field| mock_builder.stub!(field) }
  mock_builder
end

describe HouseOfCommonsSitting, ', the class' do
  it 'should respond to find_by_date' do
    lambda {HouseOfCommonsSitting.find_by_date('1999-02-08')}.should_not raise_error
  end

  it 'should have uri_component equal to "commons"' do
    HouseOfCommonsSitting.uri_component.should == 'commons'
  end
end

describe HouseOfCommonsSitting, 'an instance' do

  before do
    @sitting = HouseOfCommonsSitting.new
    @debates = Debates.new
    @sitting.debates = @debates
    @sitting.save!
  end

  after do
    Sitting.find(:all).each {|s| s.destroy}
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
    @model = mock_sitting
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
    @sitting = mock_sitting
  end

  it "should have a 'housecommons' tag" do
    @sitting.to_xml.should match(/<housecommons>.*?<\/housecommons>/m)
  end

  it "should have an 'image' tag whose 'src' attribute contains the sitting's start_image_src" do
    @sitting.to_xml.should match(/<image src="source"\/>/)
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

  it "should render it's text" do
    @sitting.to_xml.should match(/some text/)
  end

  it "should call the to_xml method on each of it's debates, passing it's xml builder" do
    Builder::XmlMarkup.should_receive(:new).and_return(@mock_builder)
    debates = mock_model(Debates)
    @sitting.debates = debates
    debates.should_receive(:to_xml).with(:builder => @mock_builder, :current_image_src => "source", :current_column => 1)
    @sitting.to_xml
  end

end


describe HouseOfCommonsSitting, " destroy" do

  it 'should destroy child debates, oral questions, sections, contributions, divisions and votes' do
    sitting = HouseOfCommonsSitting.new
    sitting.debates = Debates.new(:sitting => sitting)

    sitting.debates.sections << Section.new(:title=>'PRIVATE BUSINESS', :sitting => sitting)
    sitting.debates.sections[0].sections << Section.new(:title=>'ANGLE ORE AND TRANSPORT COMPANY BILL [Lords]', :sitting => sitting)
    sitting.debates.sections[0].sections[0].contributions << ProceduralContribution.new(:text=>"<i>Queen's Consent, on behalf of the Crown, signified.</i>")

    sitting.debates.sections << OralQuestions.new(:title => 'ORAL ANSWERS TO QUESTIONS', :sitting => sitting)
    sitting.debates.sections[1].sections << OralQuestionsSection.new(:title => 'GOVERNMENT INFORMATION SERVICES', :sitting => sitting)
    sitting.debates.sections[1].sections[0].questions << OralQuestionSection.new(:title => 'Television Films', :sitting => sitting)
    sitting.debates.sections[1].sections[0].questions[0].contributions << MemberContribution.new(:question_no=>1, :xml_id=>"S5CV0602P0-00252", :member=>"Mr. John Hall", :text=>"<p>asked the Chancellor of the Duchy of Lancaster what steps he has taken to ensure that an adequate supply of suitable British filmed material is available to countries starting television services.</p>")

    sitting.debates.sections << Section.new(:title => 'ANGLO-EGYPTIAN FINANCIAL AGREEMENT', :sitting => sitting)
    sitting.debates.sections[2].contributions << MemberContribution.new(:xml_id=>"S5CV0602P0-00641", :member=>"Mr. George Chetwynd", :member_constituency=>"(Stockton-on-Tees)", :text => 'For the right hon. Gentleman, yes.')
    sitting.debates.sections[2].contributions << DivisionPlaceholder.new
    sitting.debates.sections[2].contributions[1].division = Division.new(:name=>'Division No. 65.]',:time_text=>'10.00 p.m.')
    sitting.debates.sections[2].contributions[1].division.votes << AyeVote.new(:name=>'Agnew, Sir Peter')
    sitting.debates.sections[2].contributions[1].division.votes << NoeVote.new(:name=>'Abse, Leo')

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
