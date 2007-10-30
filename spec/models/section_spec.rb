require File.dirname(__FILE__) + '/section_spec_helper'

def mock_section_builder
  mock_builder = mock("xml builder")
  mock_builder.stub!(:title)
  mock_builder.stub!(:section).and_yield
  mock_builder
end

describe Section, " in a sitting on a date" do

  before(:each) do
    sitting = mock(Sitting)
    @year = 1999
    @date = Date.new(@year,12,31)
    sitting.stub!(:year).and_return(@year)
    sitting.stub!(:date).and_return(@date)

    @model = Section.new
    @model.stub!(:create_slug).and_return('')
    @model.stub!(:sitting).and_return(sitting)
  end

  it "should return year based on parent sitting's year" do
    @model.year.should == @year
  end

  it "should return date based on parent sitting's year" do
    @model.date.should == @date
  end
end

describe Section, " in general" do

  before(:each) do

    Section.stub!(:acts_as_solr)
    @model = Section.new
    @section = @model
    @mock_builder = mock_section_builder
  end

  it_should_behave_like "an xml-generating model"

  it " should be able to give its previous section" do
    previous_section = Section.new
    sitting = Sitting.new
    sitting.sections = [previous_section, @section]
    sitting.save!
    @section.previous_section.should == previous_section
  end

  it "should be able to give its previous linkable section" do
    previous_section = Section.new
    previous_linkable_section = Section.new(:title => "i have a title")
    sitting = Sitting.new
    sitting.sections = [previous_linkable_section, previous_section, previous_section, @section]
    sitting.save!
    @section.previous_linkable_section.should == previous_linkable_section
  end

  it " should be able to give its next section" do
    next_section = Section.new
    sitting = Sitting.new
    sitting.sections = [@section, next_section]
    sitting.save!
    @section.next_section.should == next_section
  end

  it "should be able to give its next linkable section" do
    next_section = Section.new
    next_linkable_section = Section.new(:title => "i have a title")
    sitting = Sitting.new
    sitting.sections = [@section, next_section, next_linkable_section]
    sitting.save!
    @section.next_linkable_section.should == next_linkable_section
  end

  it "should be able to tell you if it is linkable" do
    @section.respond_to?("linkable?").should be_true
  end

  it "should be linkable if it has a title" do
    @section.title = "test title"
    @section.linkable?.should be_true
  end

  it "should be linkable if it has no title, but has contributions and no parent section" do
    @section.contributions = [Contribution.new]
    @section.linkable?.should be_true
  end

  it "should not be linkable if it has no title, contributions or parent section" do
    @section.linkable?.should_not be_true
  end

end

describe Section, ".plain_title" do

  before do
    @section = Section.new(:sitting => Sitting.new)
  end

  it "should get rid of <lb>, <lb/> and </lb>" do
    @section.title = "seriously <lb>unclean <lb/>title</lb>"
    @section.plain_title.should == "seriously unclean title"
  end

  it "should remove excess spaces" do
    @section.title = "I    speak    quite     slowly"
    @section.plain_title.should == "I speak quite slowly"
  end

end

describe Section, ".to_param" do

  before do
    @section = Section.new(:sitting => Sitting.new)
  end

  it "should return the slug" do
    @section.slug = "test"
    @section.slug.should_not be_nil
    @section.to_param.should == @section.slug
  end

end

describe Section, " on creation" do

  before do
    @section = Section.new(:sitting => Sitting.new)
  end

  it "should create and save the section's slug" do
    @section.title = "New slug"
    @section.slug.should be_nil
    @section.save!
    @section.slug.should == "new-slug"
  end

  it "should create a slug which is unique within the sitting" do
    @existing_title_section = Section.new(:title => "New slug")
    @existing_title_section.sitting = Sitting.new
    @existing_title_section.sitting.sections.stub!(:find_by_slug)
    @existing_title_section.sitting.sections.should_receive(:find_by_slug).with("new-slug").and_return(@section)
    @existing_title_section.save!
    @existing_title_section.slug.should_not == "new-slug"

    @existing_title_section.destroy
  end

end


describe Section, ".create_slug" do

  before do
    @section = Section.new(:sitting => Sitting.new)
  end

  it "should return 'value-added-tax' for a section titled 'Value Added Tax'" do
    @section.title = "Value Added Tax"
    @section.create_slug.should == "value-added-tax"
  end

  it "should return 'tax-collection-wales' for 'Tax Collection (Wales)'" do
    @section.title = "Tax Collection (Wales)"
    @section.create_slug.should == "tax-collection-wales"
  end

  it "should return 'multi-role-combat-aircraft' or 'multi-rle-combat-aircraft' for 'Multi-rôle Combat Aircraft'" do
    @section.title = "Multi-rôle Combat Aircraft"
    @section.create_slug.should match(/^multi-ro?le-combat-aircraft$/)
  end

  it "should return 'multi-role-combat-aircraft' or 'multi-rle-combat-aircraft' for 'Multi-R&#x00F4;le Combat Aircraft'" do
    @section.title = "Multi-R&#x00F4;le Combat Aircraft"
    @section.create_slug.should match(/^multi-ro?le-combat-aircraft$/)
  end

  it "should return 40 characters or less, without cropping words in half" do
    @section.title = "A really long title with more than 40 characters"
    @section.create_slug.length.should <= Section::MAX_SLUG_LENGTH
    @section.create_slug[-2..-1].should == "40"
  end

  it "should crop a title starting with a word longer than the maximum slug length to the max length" do
    @section.title = "antidisestablishmentarianismandallthatjazzetcetcetc"
    @section.create_slug.length.should <= Section::MAX_SLUG_LENGTH
  end

end

describe Section, ".to_xml" do

  before do
    @mock_builder = mock_section_builder
    @section = Section.new
    @subsection_class = Section
    @contribution_class = Contribution
  end

  it "should have a 'section' tag as it's outer element" do
    @section.to_xml.should have_tag("section", :count => 1)
  end

  it "should have one 'title' tag containing the title " do
    @section.title = "test title"
    @section.to_xml.should have_tag("title", :text => "test title", :count => 1)
  end

  it_should_behave_like "a section to_xml method"

end

describe Section, ".first_image_source" do

  it "should return the first image source " do
    section = Section.new(:start_image_src => "image2")
    section.first_image_source.should == "image2"
  end

  it "should return nil if the contribution has no image sources" do
    section = Section.new(:start_image_src => nil)
    section.first_image_source.should be_nil
  end

end

describe Section, ".first_col" do
  it "should return the first column number " do
    section = Section.new(:start_column => 42)
    section.first_col.should == 42
  end

  it "should return nil if the contribution has no column numbers " do
    section = Section.new(:start_column => nil)
    section.first_col.should be_nil
  end

  it "should not return a number less than 1" do
    section = Section.new(:start_column => 0)
    section.first_col.should be_nil
  end
end

describe Section, 'when it has a parent section' do
  include SectionSpecHelper
  before do; make_written_answers; end
  after do; destroy_sitting; end

  it 'should return for preceding_sibling a preceding section with the same parent section' do
    @second_answer.preceding_sibling.should == @first_answer
  end

  it 'should return nil for preceding_sibling if there is no preceding section with the same parent section' do
    @first_answer.preceding_sibling.should be_nil
  end

end

describe Section, 'when it is directly under sitting' do
  include SectionSpecHelper
  before(:all) do; make_written_answers; end
  after(:all) do; destroy_sitting; end

  it 'should return for preceding_sibling a preceding section that is directly under sitting' do
    @solo_answer.preceding_sibling.should == @parent_answer
  end

  it 'should return nil for preceding_sibling if there is no preceding section directly under sitting' do
    @parent_answer.preceding_sibling.should be_nil
  end
end

describe Section, 'when a section is directly under debates section' do
  include SectionSpecHelper
  before do; make_sitting; end
  after do; destroy_sitting; end

  it 'should return for preceding_sibling a preceding section that is directly under debates' do
    @solo.preceding_sibling.should == @parent
  end

  it 'should return nil for preceding_sibling if there is no preceding section directly under debates' do
    @parent.preceding_sibling.should be_nil
  end

  it 'should unnest so new parent section id is the debates section id' do
    @first.parent_section_id.should == @parent.id
    @first.can_be_unnested?.should be_true
    @first.parent_section.parent_section.should == @debates
    @first.unnest!
    @first.reload
    @first.parent_section.should == @debates
  end
end

describe Section, 'when it has a preceding sibling section' do
  include SectionSpecHelper
  before do; make_sitting; end
  after do; destroy_sitting; end

  it 'should nest so new parent id is the former preceding sibling id' do
    @second.parent_section_id.should == @parent.id
    @second.nest!
    @second.parent_section_id.should == @first.id
  end
end

describe Section, 'when it has following sibling sections' do
  include SectionSpecHelper
  before do; make_sitting; end
  after do; destroy_sitting; end

  it 'should have following_siblings return array of following sibling sections' do
    @first.following_siblings.should == [@second, @third]
  end
end

describe Section, 'when it has a following sibling section' do
  include SectionSpecHelper
  before do; make_sitting; end
  after do; destroy_sitting; end

  it 'should have following_siblings return array containing the one following sibling section' do
    @second.following_siblings.should == [@third]
  end
end

describe Section, 'when it has no following sibling sections' do
  include SectionSpecHelper
  before do; make_sitting; end
  after do; destroy_sitting; end

  it 'should have following_siblings return an empty array' do
    @third.following_siblings.should == []
  end
end

describe Section, 'when unnested and there are following sibling sections' do
  include SectionSpecHelper
  before do; make_sitting; end
  after do; destroy_sitting; end

  it 'should unnest section and following sibling sections' do
    @first.parent_section_id.should  == @parent.id
    @second.parent_section_id.should == @parent.id
    @third.parent_section_id.should  == @parent.id

    @first.should_receive(:following_siblings).and_return([@second, @third])
    @second.should_receive(:unnest!).with(false)
    @third.should_receive(:unnest!).with(false)
    @first.unnest!
    @first.parent_section_id.should  == @debates.id
  end
end

describe Section, 'when it has an OralQuestionsSection as a parent' do
  include SectionSpecHelper
  before do; make_sitting_with_oral_answers; end
  after do; destroy_sitting; end

  it 'should unnest section and following sibling sections' do
    @first_question.parent_section_id.should == @oral_questions_section.id
    @second_question.parent_section_id.should == @oral_questions_section.id
    @third_question.parent_section_id.should == @oral_questions_section.id
    @oral_questions.sections.size.should == 1
    @first_question.should_receive(:following_siblings).and_return([@second_question, @third_question])
    @first_question.unnest!
    @first_question.parent_section_id.should == @oral_questions.id
    @second_question.parent_section_id.should == @oral_questions.id
    @third_question.parent_section_id.should == @oral_questions.id
    @oral_questions.reload
    @oral_questions.sections.size.should == 4
  end
end

describe Section, 'can_be_nested?' do
  it 'should be true if there is a preceding sibling' do
    section = Section.new
    section.stub!(:preceding_sibling).and_return(mock(Section))
    section.can_be_nested?.should be_true
  end

  it 'should be false if there is no preceding sibling' do
    section = Section.new
    section.stub!(:preceding_sibling).and_return(nil)
    section.can_be_nested?.should be_false
  end
end

describe Section, 'can_be_unnested?' do
  it 'should be true if there is a parent section' do
    section = Section.new
    section.stub!(:parent_section).and_return(mock(Section))
    section.can_be_unnested?.should be_true
  end

  it 'should be false if there is a parent section that is a debates section' do
    section = Section.new
    debates = Debates.new
    section.stub!(:parent_section).and_return debates
    section.can_be_unnested?.should be_false
  end

  it 'should be false if there is no parents section' do
    section = Section.new
    section.stub!(:parent_section).and_return(nil)
    section.can_be_unnested?.should be_false
  end
end

describe Section, ' when returning frequent titles in an interval' do

  before(:all) do
    @start_date = Date.new(1996, 1, 1)
    @end_date = Date.new(1997, 12, 31)
    @sitting = Sitting.new(:date => Date.new(1997, 6, 1))
    @first_common = Section.new(:title => "common title")
    @second_common = Section.new(:title => "common title")
    @less_common = Section.new(:title => "less common title")
    @sitting.sections = [@first_common, @second_common, @less_common]
    @sitting.save!
  end

  it 'should return a list of titles starting with the most common' do
    Section.frequent_titles_in_interval(@start_date, @end_date).should == ['common title', 'less common title']
  end

  it 'should exclude any titles passed in the exclude parameter' do
    Section.frequent_titles_in_interval(@start_date, @end_date, :exclude => ['less common title']).should == ['common title']
  end

  it 'should return only the number of results requested' do
    Section.frequent_titles_in_interval(@start_date, @end_date, :limit => 1).should == ['common title']
  end

  it 'should be able to return sections in an interval with a given title' do
    Section.find_by_title_in_interval("common title", @start_date, @end_date).should == [@first_common, @second_common]
  end

  after(:all) do
    @sitting.destroy
  end

end
