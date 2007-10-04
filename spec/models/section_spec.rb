require File.dirname(__FILE__) + '/../spec_helper'

def mock_section_builder
  mock_builder = mock("xml builder")
  mock_builder.stub!(:title)
  mock_builder.stub!(:section).and_yield
  mock_builder
end

describe Section, " in general" do

  before(:each) do
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

describe Section, ".title_cleaned_up" do

  before do
    @section = Section.new(:sitting => Sitting.new)
  end

  it "should get rid of <lb>, <lb/> and </lb>" do
    @section.title = "seriously <lb>unclean <lb/>title</lb>"
    @section.title_cleaned_up.should == "seriously unclean title"
  end

  it "should remove excess spaces" do
    @section.title = "I    speak    quite     slowly"
    @section.title_cleaned_up.should == "I speak quite slowly"
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
    @existing_title_section.create_slug.should_not == "new-slug"
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
