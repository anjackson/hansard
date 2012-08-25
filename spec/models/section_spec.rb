require File.dirname(__FILE__) + '/section_spec_helper'
require File.dirname(__FILE__) + '/../../app/models/act'
require File.dirname(__FILE__) + '/../../app/models/bill'


def mock_section_builder
  mock_builder = mock("xml builder")
  mock_builder.stub!(:title)
  mock_builder.stub!(:section).and_yield
  mock_builder
end

def mock_section_with_parent parent
  mock_model(Section, :parent_section => parent)
end

def mock_sitting_with_sections sections
  mock_model(Sitting, :all_sections => sections)
end

describe Section do
  describe "in a sitting on a date" do

    before(:each) do
      @sitting_type = "sitting"
      @hansard_reference = 'hansard reference'
      @sitting_class = Sitting
      @year = 1999
      @month = 12
      @date = Date.new(@year, @month, 31)
      @title = "sitting title"
      @uri_component = "commons"
      @sitting = mock(Sitting, :null_object => true,
                              :sitting_type_name => @sitting_type,
                              :class => @sitting_class,
                              :year => @year,
                              :date => @date,
                              :title => @title,
                              :uri_component => @uri_component,
                              :hansard_reference => @hansard_reference)
      @section = Section.new(:date => @date, :start_column => '4', :end_column => '5')
      @section.stub!(:sitting).and_return(@sitting)
    end

    it "should return year based its date" do
      @section.year.should == @year
    end

    it "should return month based on its date" do
      @section.month.should == @month
    end

    it 'should return a sitting title equal to its sitting\'s title' do
      @section.sitting_title.should == @title
    end

    it 'should return a sitting uri component equal to its sitting\'s uri component' do
      @section.sitting_uri_component.should == @uri_component
    end

    it 'should return a sitting class equal to its sitting\'s class' do
      @section.sitting_class.should == @sitting_class
    end

    it 'should return a sitting type equal to its sittings\'s sitting type name' do
      @section.sitting_type.should == @sitting_type
    end

    it 'should return its sitting\'s hansard reference for the section\' first column' do
      @section.hansard_reference.should == @hansard_reference
    end
    
    it "should return its sitting's column reference for the section's columns" do
      @sitting.should_receive(:column_reference).with('4', '5')
      @section.column_reference
    end
    
  end

  describe ".word_count" do

    before do
      @section = Section.new
      @first_contribution = Contribution.new(:text => "one two three four five")
      @second_contribution = Contribution.new
      @third_contribution = Contribution.new(:text => "six seven")
      @section.contributions = [@first_contribution, @second_contribution, @third_contribution]
    end


    it 'should be the sum of the length of text belonging to the section\'s contributions' do
      @section.word_count.should == 7
    end

    it 'should include the character length of unlinkable child sections' do
      @fourth_contribution = Contribution.new(:text => "eight nine")
      subsection = Section.new(:contributions => [@fourth_contribution])
      subsection.stub!(:linkable?).and_return(false)
      @section.sections << subsection
      @section.word_count.should == 9
    end

  end

  describe "in general" do

    before(:each) do
      @model = Section.new
      @section = @model
      @mock_builder = mock_section_builder
    end

    it_should_behave_like "an xml-generating model"

    it " should be able to give its previous section" do
      previous_section = Section.new
      sitting = Sitting.new :date => '2007-12-12'
      sitting.direct_descendents = [previous_section, @section]
      sitting.save!
      @section.previous_section.should == previous_section
    end

    it "should be able to give its previous linkable section" do
      section = Section.new
      previous_section = mock_model(Section, :linkable? => false)
      previous_linkable_section = mock_model(Section, :linkable? => true)
      section.stub!(:sitting).and_return mock_model(Sitting, :all_sections => [previous_linkable_section, previous_section, section])

      section.previous_linkable_section.should == previous_linkable_section
    end

    it " should be able to give its next section" do
      next_section = Section.new
      sitting = Sitting.new :date => '2007-12-12'
      sitting.direct_descendents = [@section, next_section]
      sitting.save!
      @section.next_section.should == next_section
    end

    it "should be able to give its next linkable section" do
      next_section = Section.new
      next_linkable_section = Section.new(:title => "i have a title")
      sitting = Sitting.new :date => '2007-12-12'
      sitting.direct_descendents = [@section, next_section, next_linkable_section]
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

    it "should not be linkable if it has no title, has contributions, and has no parent section" do
      @section.contributions = [Contribution.new]
      @section.linkable?.should be_false
    end

    it "should not be linkable if it has no title, contributions or parent section" do
      @section.linkable?.should_not be_true
    end

    it 'should be able to list its parent sections' do
      parent_section = Section.new
      grandparent_section = Section.new
      @section.stub!(:parent_section).and_return(parent_section)
      parent_section.stub!(:parent_section).and_return(grandparent_section)
      @section.parent_sections.should == [parent_section, grandparent_section]
    end

    it 'should return preceding contribution given a contribution' do
      preceding_contribution = mock('contribution')
      contribution = mock('contribution')
      @section.stub!(:contributions).and_return [preceding_contribution, contribution]
      @section.preceding_contribution(contribution).should == preceding_contribution
      @section.preceding_contribution(preceding_contribution).should == nil
    end

    it 'should return following contribution given a contribution' do
      contribution = mock('contribution')
      following_contribution = mock('contribution')
      @section.stub!(:contributions).and_return [contribution, following_contribution]
      @section.following_contribution(contribution).should == following_contribution
      @section.following_contribution(following_contribution).should == nil
    end
  end

  describe ".sitting_type" do

    it 'should be "Written Answers" for a section belonging to a WrittenAnswersSitting' do
      sitting = WrittenAnswersSitting.new :date => '2007-12-12'
      section = Section.new
      section.sitting = sitting
      section.sitting_type.should == 'Written Answers'
    end

  end

  describe "on saving" do
    it 'should call clean_title' do
      @section = Section.new :sitting => Sitting.new(:date => '2007-12-12')
      @section.should_receive(:clean_title)
      @section.valid?
    end
  end

  describe 'when cleaning title on creation' do

    def check_title_cleaned title, expected
      section = Section.new :title=>title
      Bill.should_receive(:correct_HL_variants).with(title).and_return title
      section.clean_title
      section.title.should == expected
    end

    it "should remove <lb>, <lb/> and </lb> from title" do
      check_title_cleaned "seriously <lb>unclean <lb/>title</lb>", "seriously unclean title"
    end

    it 'should remove single <lb/> from title' do
      check_title_cleaned 'A<lb/>title', 'A title'
    end

    it 'should remove new line char' do
      check_title_cleaned "MINISTRY OF HEALTH PROVISIONAL ORDER BILL.\n[H.L.]", "MINISTRY OF HEALTH PROVISIONAL ORDER BILL. [H.L.]"
    end

    it "should remove excess spaces in title" do
      check_title_cleaned "I    speak    quite     slowly", "I speak quite slowly"
    end

    it "should correct known text issues in title" do
      check_title_cleaned "MINISTRY OF HEALTH PROVI<lb/> SIONAL ORDER (TORQUAY) BILL.", "MINISTRY OF HEALTH PROVISIONAL ORDER (TORQUAY) BILL."
    end

    it 'should remove unmatched (" from front of title' do
      check_title_cleaned '("APPENDIX (C).', 'APPENDIX (C).'
    end

    it 'should remove unmatched double quote from front of title' do
      check_title_cleaned '"THIRD SCHEDULE', 'THIRD SCHEDULE'
    end

    it 'should leave matching double quotes untouched' do
      check_title_cleaned '"STOP-THE-WAR" POST-CARDS.', '"STOP-THE-WAR" POST-CARDS.'
    end

    it 'should remove surrounding square brackets' do
      check_title_cleaned '[HOLYHEAD HARBOUR LEASING.]', 'HOLYHEAD HARBOUR LEASING.'
    end

    it 'should leave matched square brackets in title untouched' do
      check_title_cleaned 'WOLVERTON ESTATE BILL. [H.L.]', 'WOLVERTON ESTATE BILL. [H.L.]'
    end

    it 'should put a space between number and text at start of title' do
      check_title_cleaned '1.GRATUITY TO LEGAL REPRESENTATIVE.', '1. GRATUITY TO LEGAL REPRESENTATIVE.'
    end

    it 'should replace " OP " with " OF "' do
      check_title_cleaned 'BANK OP ENGLAND BILL.', 'BANK OF ENGLAND BILL.'
    end

    it 'should strip an unmatched trailing square bracket' do
      check_title_cleaned "FEMALE EMIGRATION.]", "FEMALE EMIGRATION."
    end
    
    it 'should strip surrounding square brackets followed by a fullstop and dash' do 
      check_title_cleaned "[KING'S SPEECH].&#x2014;", "KING'S SPEECH.&#x2014;"
    end
    
    it 'should strip surrounding square brackets followed by a dash' do
      check_title_cleaned "[WARIN INDIA.]&#x2014;", "WARIN INDIA.&#x2014;"
    end
    
    it 'should strip surrounding square brackets followed by a fullstop' do 
      check_title_cleaned "[SURPLUS OF THE CONSOLIDATED FUND].", "SURPLUS OF THE CONSOLIDATED FUND."
    end

  end

  describe ".to_param" do

    before do
      @section = Section.new(:sitting => Sitting.new(:date => '2007-12-12'))
    end

    it "should return the slug" do
      @section.slug = "test"
      @section.slug.should_not be_nil
      @section.to_param.should == @section.slug
    end

  end

  describe "when returning members in a section" do

    it "should return an empty list the first time it's called" do
      section = Section.new
      section.members_in_section.should == []
    end

    it "should return the existing list on subsequent calls" do
      section = Section.new
      section.members_in_section << 12
      section.members_in_section.should == [12]
    end

  end

  describe "on creation" do

    before do
      @sitting = mock_model(Sitting, :date => '2007-12-12', :all_sections => [])
      @section = Section.new(:sitting => @sitting)
    end

    it "should create and save the section's slug" do
      @section.title = "New slug"
      @section.slug.should be_nil
      @section.sitting.all_sections.stub!(:find_by_slug)
      @section.save!
      @section.slug.should == "new-slug"
    end

    it "should create a slug which is unique within the sitting" do
      @existing_title_section = Section.new(:title => "New slug")
      @existing_title_section.sitting = Sitting.new :date => '2007-12-12'
      @existing_title_section.sitting.all_sections.stub!(:find_by_slug)
      @existing_title_section.sitting.all_sections.should_receive(:find_by_slug).with("new-slug").and_return(@section)
      @existing_title_section.save!
      @existing_title_section.slug.should_not == "new-slug"
    end

    it 'should look for the most recent section in the sitting with a blank title slug if the title is blank and return 1 plus that index' do
      most_recent_blank_conditions = { :conditions => ["title is null"], :order => "id desc" }
      @section.sitting.all_sections.should_receive(:find).with(:first, most_recent_blank_conditions).and_return(mock_model(Section, :slug => '-3'))
      @section.slug_start_index('').should == 4
    end

  end


  describe ".create_slug" do

    before do
      @section = Section.new(:sitting => Sitting.new(:date => '2007-12-12'))
    end

    def check_slug title, slug
      @section.title = title
      @section.create_slug.should == slug
    end

    it "should return 'mediation-of-russia' for '[MEDIATION OF RUSSIA.]—'" do
      check_slug "[MEDIATION OF RUSSIA.]—", 'mediation-of-russia'
    end

    it "should return 'value-added-tax' for a section titled 'Value Added Tax'" do
      check_slug "Value Added Tax", "value-added-tax"
    end

    it "should return 'tax-collection-wales' for 'Tax Collection (Wales)'" do
      check_slug "Tax Collection (Wales)", "tax-collection-wales"
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

  describe ".to_xml" do

    before do
      @mock_builder = mock_section_builder
      @section = Section.new
      @subsection_class = Section
      @contribution_class = Contribution
    end

    it "should have a 'section' tag as it's outer element" do
      @section.to_xml.should have_tag("section", :count => 1)
    end

    it "should have one 'title' tag containing the escaped title " do
      @section.title = "test &title"
      @section.to_xml.should have_tag("title", :text => "test &amp;title", :count => 1)
    end

    it_should_behave_like "a section to_xml method"

  end

  describe ".start_column" do

    it "should return the first column if it is just a number" do
      section = Section.new(:start_column => '42')
      section.start_column.should == '42'
    end

    it "should return the first column as a number if it is a number plus a letter suffix" do
      section = Section.new(:start_column => '42WH')
      section.start_column.should == '42WH'
    end

    it "should return nil if the contribution has no column numbers " do
      section = Section.new(:start_column => nil)
      section.start_column.should be_nil
    end

  end

  describe "when getting its first member" do

    it "should return the name of the member who spoke it's first contribution if it has contributions" do
      @section = Section.new
      @section.contributions << Contribution.new(:member_name => 'test member')
      @section.first_member.should == 'test member'
    end

    it "should ask its first sub-section for its first member if it has no contributions, and has sections" do
      @section = Section.new
      @sub_section = Section.new
      @sub_section.contributions << Contribution.new(:member_name => 'test member')
      @section.sections << @sub_section
      @section.first_member.should == 'test member'
    end

  end

  describe 'when it has a parent section' do

    it 'should return for preceding_sibling a preceding section with the same parent section' do
      section, parent_section, preceding_sibling = Section.new, mock(Section), mock_model(Section)

      parent_section.should_receive(:sections).and_return [preceding_sibling, section]
      section.should_receive(:parent_section).any_number_of_times.and_return parent_section
      section.preceding_sibling.should == preceding_sibling
    end

    it 'should return nil for preceding_sibling if there is no preceding section with the same parent section' do
      section, parent_section, following_sibling = Section.new, mock(Section), mock_model(Section)

      parent_section.should_receive(:sections).and_return [section, following_sibling]
      section.should_receive(:parent_section).any_number_of_times.and_return parent_section
      section.preceding_sibling.should be_nil
    end

  end

  describe 'when it is directly under sitting' do
    include SectionSpecHelper
    before(:all) do; make_written_answers; end

    it 'should return for preceding_sibling a preceding section that is directly under sitting' do
      @solo_answer.preceding_sibling.should == @parent_answer
    end

    it 'should return nil for preceding_sibling if there is no preceding section directly under sitting' do
      @parent_answer.preceding_sibling.should be_nil
    end
  end

  describe 'when sections are directly under debates section' do
    it 'should return for preceding_sibling a preceding section that is directly under debates' do
      section, debates, preceding_sibling = Section.new, mock(Debates), mock_model(Section)

      debates.should_receive(:sections).and_return [preceding_sibling, section]
      section.should_receive(:parent_section).any_number_of_times.and_return debates

      section.preceding_sibling.should == preceding_sibling
    end

    it 'should return nil for preceding_sibling if there is no preceding section directly under debates' do
      section, debates = Section.new, mock_model(Debates)
      debates.should_receive(:sections).and_return [section]
      section.should_receive(:parent_section).twice.and_return debates

      section.preceding_sibling.should be_nil
    end

    it 'should unnest so new parent section is the debates section' do
      debates_section = mock_model(Debates)
      parent_section = mock_section_with_parent(debates_section)

      section = Section.new
      section.stub!(:parent_section).and_return parent_section
      section.stub!(:following_siblings).and_return []
      section.stub!(:can_be_unnested?).and_return true

      section.should_receive(:parent_section=).with(debates_section)
      section.should_receive(:save!)

      section.unnest!
    end
  end

  describe 'when it has a preceding sibling section' do

    it 'should nest so new parent id is the former preceding sibling id' do
      preceding_sibling = mock_model(Section)
      section = Section.new
      section.stub!(:preceding_sibling).and_return preceding_sibling
      section.stub!(:can_be_unnested?).and_return true

      section.should_receive(:parent_section=).with(preceding_sibling)
      section.should_receive(:save!)
      section.nest!
    end
  end

  describe 'when it has following sibling sections' do

    it 'should have following_siblings return array of following sibling sections' do
      parent = mock_model(Section)
      first = Section.new
      first.stub!(:parent_section).and_return parent

      second = mock_section_with_parent(parent)
      third = mock_section_with_parent(parent)
      sitting = mock_sitting_with_sections([first,second,third])
      first.stub!(:sitting).and_return sitting

      first.following_siblings.should == [second, third]
    end
  end

  describe 'when it has a following sibling section' do

    it 'should have following_siblings return array containing the one following sibling section' do
      parent = mock_model(Section)
      second = Section.new
      second.stub!(:parent_section).and_return parent

      first = mock_section_with_parent(parent)
      third = mock_section_with_parent(parent)
      sitting = mock_sitting_with_sections([first,second,third])
      second.stub!(:sitting).and_return sitting

      second.following_siblings.should == [third]
    end
  end

  describe 'when it has no following sibling sections' do

    it 'should have following_siblings return an empty array' do
      parent = mock_model(Section)
      third = Section.new
      third.stub!(:parent_section).and_return parent

      first = mock_section_with_parent(parent)
      second = mock_section_with_parent(parent)
      sitting = mock_sitting_with_sections([first,second,third])
      third.stub!(:sitting).and_return sitting

      third.following_siblings.should == []
    end
  end

  describe 'when unnested and there are following sibling sections' do

    it 'should unnest section and following sibling sections' do
      section = Section.new
      section.stub!(:parent_section).and_return mock_section_with_parent(mock_model(Debates))
      section.stub!(:parent_section=)
      section.stub!(:save!)
      section.stub!(:can_be_unnested?).and_return true

      second = mock_model(Section)
      third = mock_model(Section)

      second.should_receive(:unnest!).with(false)
      third.should_receive(:unnest!).with(false)
      section.should_receive(:following_siblings).and_return [second, third]

      section.unnest!
    end
  end

  describe 'can_be_nested?' do
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

  describe 'can_be_unnested?' do
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

  describe 'when asked if it is a written body' do 
  
    it 'should return false' do 
      section = Section.new
      section.is_written_body?.should be_false
    end
  
  end

  describe "before validation on creation" do

    it 'should populate act mentions in it\'s title' do
      section = Section.new(:title => "test text")
      section.stub!(:create_slug)
      Act.should_receive(:populate_mentions).with("test text", section, nil).and_return([])
      section.valid?
    end

    it 'should populate bill mentions in it\'s title' do
      section = Section.new(:title => "test text")
      section.stub!(:create_slug)
      Bill.should_receive(:populate_mentions).with("test text", section, nil).and_return([])
      section.valid?
    end
  end

  describe "when giving a title via it's associations" do

    before do
      @sitting = Sitting.new :date => '2007-12-12'
      @parent_section = Section.new
      @section = Section.new(:sitting => @sitting, :parent_section => @parent_section)
    end

    it 'should return its own title if it has one' do
      @section.stub!(:title).and_return("own section title")
      @section.title_via_associations.should == "own section title"
    end

    it 'should return its parent\'s title if it hasn\'t a title itself' do
      @section.stub!(:title).and_return("")
      @parent_section.stub!(:title).and_return("parent title")
      @section.title_via_associations.should == "parent title"
    end

    it 'should return its sitting\'s title if it has no title and its parent sections have no title' do
      @section.stub!(:title)
      @parent_section.stub!(:title)
      @sitting.stub!(:title).and_return("sitting title")
      @section.title_via_associations.should == "sitting title"
    end

  end

  describe 'when adding contribution' do

    it 'should set section on contribution' do
      section = Section.new
      section.stub!(:contributions).and_return []

      contribution = mock_model(Contribution)
      contribution.should_receive(:section=).with(section)
      section.add_contribution contribution
    end

    it 'should add contribution to contributions list' do
      contribution = mock_model(Contribution)
      contribution.stub!(:section=)

      contributions = mock(Array)
      contributions.should_receive(:<<).with(contribution)

      section = Section.new
      section.stub!(:contributions).and_return contributions
      section.add_contribution contribution
    end

  end

  describe 'when adding child section' do

    before do 
      @child = mock_model(Section)
      @child.stub!(:parent_section=)
      @section = Section.new
    end
    
    it 'should set parent_section on section' do
      @child.should_receive(:parent_section=).with(@section)
      @section.add_section @child
    end

    it 'should add section to sections list' do
      @section.add_section @child
      @section.sections.should == [@child]
    end
    
  end

  describe "when adding clause section to orders of the day section, and the clause's preceding sibling is a bill debate section" do

    before do 
      @bill_debate = mock_model(Section, :is_bill_debate? => true, :sections => [])
      @clause = mock_model(Section, :is_clause? => true, :parent_section= => nil)
      @orders_of_the_day = Section.new
      @orders_of_the_day.stub!(:is_orders_of_the_day?).and_return true
      @orders_of_the_day.stub!(:sections).and_return [@bill_debate]
    end
    
    it 'should set parent_section on clause section to be the preceding bill section sibling' do
      @clause.should_receive(:parent_section=).with(@bill_debate)
      @orders_of_the_day.add_section @clause
    end

    it 'should add the clause section to the sections list of the preceding bill section' do
      @orders_of_the_day.add_section @clause
      @bill_debate.sections.should == [@clause]
    end
    
    it 'should add the clause to the parent if there is no preceding sibling' do 
      @orders_of_the_day.stub!(:sections).and_return []
      @orders_of_the_day.add_section @clause
      @orders_of_the_day.sections.should == [@clause]
    end
    
  end

  describe 'when title starts with "clause" or "new clause"' do
    it 'should have is_clause? return true' do
      Section.new(:title => 'CLAUSE X').is_clause?.should be_true
      Section.new(:title => 'Clause X').is_clause?.should be_true
      Section.new(:title => 'NEW CLAUSE X').is_clause?.should be_true
      Section.new(:title => 'New Clause X').is_clause?.should be_true
    end
  end

  describe 'when title does not start with "clause" or "new clause"' do
    it 'should have is_clause? return false' do
      Section.new(:title => 'Random').is_clause?.should be_false
      Section.new(:title => '').is_clause?.should be_false
      Section.new(:title => nil).is_clause?.should be_false
    end
  end

  describe 'when title is orders of the day"' do
    it 'should have is_orders_of_the_day? return true' do
      Section.new(:title => "ORDERS OF THE DAY").is_orders_of_the_day?.should be_true
      Section.new(:title => "ORDERS OF THE DAY.").is_orders_of_the_day?.should be_true
      Section.new(:title => "Orders of the Day").is_orders_of_the_day?.should be_true
    end
  end

  describe 'when title is not orders of the day' do
    it 'should have is_orders_of_the_day? return false' do
      Section.new(:title => "ORDERS OF THE DAY SUPPLY").is_orders_of_the_day?.should be_false
      Section.new(:title => 'Random').is_orders_of_the_day?.should be_false
      Section.new(:title => '').is_orders_of_the_day?.should be_false
      Section.new(:title => nil).is_orders_of_the_day?.should be_false
    end
  end

  describe 'when title is business of the house"' do
    it 'should have is_business_of_the_house? return true' do
      Section.new(:title => "BUSINESS OF THE HOUSE").is_business_of_the_house?.should be_true
      Section.new(:title => "BUSINESS OF THE HOUSE,").is_business_of_the_house?.should be_true
      Section.new(:title => "BUSINESS OF THE HOUSE.").is_business_of_the_house?.should be_true
      Section.new(:title => "Business of the House").is_business_of_the_house?.should be_true
    end
  end

  describe 'when title is not business of the house' do
    it 'should have is_business_of_the_house? return false' do
      Section.new(:title => "BUSINESS OF THE HOUSE (SUPPLY)").is_business_of_the_house?.should be_false
      Section.new(:title => 'Random').is_business_of_the_house?.should be_false
      Section.new(:title => '').is_business_of_the_house?.should be_false
      Section.new(:title => nil).is_business_of_the_house?.should be_false
    end
  end

  describe 'when title is bill name"' do
    it 'should have is_bill_debate? return true' do
      title = 'Finance Bill'
      BillResolver.should_receive(:new).with(title).and_return mock(BillResolver, :references => [mock('reference')])
      Section.new(:title => title).is_bill_debate?.should be_true
    end
  end

  describe 'when title is not bill name"' do
    it 'should have is_bill_debate? return false' do
      title = 'Random'
      BillResolver.should_receive(:new).with(title).and_return mock(BillResolver, :references => [])
      Section.new(:title => title).is_bill_debate?.should be_false
    end
  end

  describe 'containing divisions' do

    before do
      @section = Section.new
    end

    it 'should be able to return a list of its divisions sorted by id number' do
      division2 = mock_model(Division, :id=>2)
      division3 = mock_model(Division, :id=>3)
      division1 = mock_model(Division, :id=>1)
      placeholders = [mock_model(DivisionPlaceholder, :division => division2), mock_model(DivisionPlaceholder, :division => division3), mock_model(DivisionPlaceholder, :division => division1)]
      @section.stub!(:contributions).and_return placeholders
      @section.divisions.should == [division1, division2, division3]
    end

    it 'should know index of a division in its divisions list' do
      division1 = mock_model(Division, :id=>1)
      division2 = mock_model(Division, :id=>2)
      division3 = mock_model(Division, :id=>3)
      @section.stub!(:divisions).and_return [division1, division2, division3]

      @section.index_of_division(division1).should == 0
      @section.index_of_division(division2).should == 1
      @section.index_of_division(division3).should == 2
    end

    it 'should return count of divisions' do
      @section.should_receive(:division_placeholders).and_return [mock('division_placeholder'), mock('unparsed_division_placeholder')]
      @section.division_count.should == 2
    end

    it 'should find division by its number' do
      division = mock_model(Division, :number=>101)
      @section.stub!(:divisions).and_return [division]
      @section.find_division('division_101').should == division
    end

    it 'should return nil when finding division by its number and there is no match' do
      division = mock_model(Division, :number=>102)
      @section.stub!(:divisions).and_return [division]
      @section.find_division('division_101').should be_nil
    end
  end

  describe 'when asked for id link' do
    it 'should return object id preceded by section_' do
      section = Section.new
      section.stub!(:id).and_return 123
      section.link_id.should ==  'section_123'
    end
  end

  describe 'when asked for mentions' do
    it 'should return all bill and act mentions not linked to a contribution, sorted by start position' do
      section = Section.new
      act_mention = mock('act_mention', :contribution_id=>1)
      bill_mention = mock('bill_mention', :contribution_id=>nil, :start_position=>10)
      section.stub!(:act_mentions).and_return [act_mention]
      section.stub!(:bill_mentions).and_return [bill_mention]
      section.mentions.should == [bill_mention]
    end
  end

  describe 'when asked for json' do
    it 'should return result of call to original json method' do
      section = Section.new
      options = mock('options')
      section.should_receive(:to_original_json).with(options)
      section.to_json(options)
    end
  end

  describe 'when asked for id_hash' do
    it "should return sitting id_hash merged with section's slug" do
      sitting = mock('sitting', :id_hash=>{:mock=>'contents'})

      section = Section.new
      section.stub!(:slug).and_return 'title'
      section.stub!(:sitting).and_return sitting

      section.id_hash.should == {:mock=>'contents', :id => 'title'}
    end
  end

  describe 'when asked for body' do
    it 'should return nil when not a WrittenAnswersBody or a WrittenAnswersSitting' do
      section = Section.new
      section.stub!(:sections).and_return [Section.new]
      section.body.should be_nil
    end
  end

  describe 'when asked to find a linkable section' do
    it 'should raise error if direction is not :previous or :next' do
      section = Section.new
      lambda { section.find_linkable_section(:bad_parameter) }.should raise_error(Exception)
    end
  end
end
