require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::WrittenAnswersParser do

  describe "when deciding what house a written answers sitting belongs to" do
    it 'should return "commons" if the sitting source file name contains "commons_writtenanswers"' do
      Hansard::WrittenAnswersParser.new('').house('commons_writtenanswers.xml').should == "commons"
    end

    it 'should return "lords" if the sitting source file name contains "lords_writtenanswers"' do
      Hansard::WrittenAnswersParser.new('').house('lords_writtenanswers.xml').should == "lords"
    end
  end

  describe "when creating written answers sittings" do
    def check_sitting_type house, expected
      parser = Hansard::WrittenAnswersParser.new('')
      parser.stub!(:house).and_return(house)
      parser.sitting_type.should == expected
    end

    it 'should create a commons written answer sitting for content from the commons' do
      check_sitting_type 'commons', CommonsWrittenAnswersSitting
    end

    it 'should create a lords written answer sitting for content from the lords' do
      check_sitting_type 'lords', LordsWrittenAnswersSitting
    end

    it 'should create a parent written answer sitting for content missing a house' do
      check_sitting_type nil, WrittenAnswersSitting
    end
  end

  describe 'when asked for the initial column' do
    describe 'and there is no column element before start of sections' do
      it 'should return first col number minus one' do
        parser = Hansard::WrittenAnswersParser.new('')
        doc = Hpricot.XML('<writtenanswers><section><col>54</col></section></writtenanswers>')
        parser.get_initial_column('writtenanswers', doc).should == '53'
      end
    end
  end

  describe "when the root element of the doc parsed is not 'writtenanswers'" do
    it "should raise an error noting the unrecognised type" do
      parser = Hansard::WrittenAnswersParser.new('')
      parser.should_receive(:load_doc)
      parser.should_receive(:get_root_name).and_return 'unknown_type'
      lambda { parser.parse }.should raise_error(Exception, /unknown_type/)
    end
  end

  describe "when parsing a Commons writtenanswers file containing group elements" do
 
    before(:all) do
      file = 'commons_writtenanswers_example.xml'
      @volume = mock_model(Volume)
      source_file = mock_model(SourceFile, :volume => @volume)
      @sitting = parse_hansard_file(Hansard::WrittenAnswersParser, data_file_path(file), data_file=nil, source_file)
  
      @sitting_type = CommonsWrittenAnswersSitting
      @sitting_date = Date.new(1985,12,16)
      @sitting_date_text = 'Monday 16 December 1985'
      @sitting_title = 'Written Answers to Questions'
      @sitting_start_column = '1'
      @sitting_end_column = '14'
      @agriculture_group = @sitting.groups[0]
      @food_storage_section = @agriculture_group.sections[0]
      @food_storage_question = @food_storage_section.body.contributions[0]
      @food_storage_answer = @food_storage_section.body.contributions[1]

      @veterinary_services_section = @agriculture_group.sections[2]

      @environment_group = @sitting.groups[1]
      @building_controls_section = @environment_group.sections[0]

      @untitled_group = @sitting.groups[2]
      @trinidad_section = @untitled_group.sections[0]
    end

    it_should_behave_like "All sittings or written answers or written statements"

    it 'should set volume on written answers' do
      @sitting.volume.should == @volume
    end

    it "should create the correct number of groups in written answers" do
      @sitting.groups.size.should == 3
    end

    it "should set nil title for a question group with no title element" do
      @untitled_group.title.should == nil
    end

    it "should set nil title for a question group with no title element" do
      @trinidad_section.title.should == 'TRINIDAD (RAILWAY COMMITTEE).'
    end

    it "should set the title correctly for a question section" do
      @agriculture_group.title.should == 'AGRICULTURE, FISHERIES AND FOOD'
    end

    it "should create the correct number of sections for a question section" do
      @agriculture_group.sections.size.should == 3
    end

    it "should set the end column on a question section" do
      @agriculture_group.end_column.should == '2'
    end

    it "should set the title correctly for a question section" do
      @food_storage_section.title.should == 'Food Storage'
    end

    it "should set model type to Section for a question section" do
      @food_storage_section.should be_an_instance_of(Section)
    end

    it "should set start column on first body section" do
      @food_storage_section.start_column.should_not be_nil
      @food_storage_section.start_column.should == '1'
    end

    it "should set end column on a body section when end column is same as start column" do
      @food_storage_section.end_column.should_not be_nil
      @food_storage_section.end_column.should == '1'
    end

    it "should set start column on a body section after first body section" do
      @veterinary_services_section.start_column.should_not be_nil
      @veterinary_services_section.start_column.should == '1'
    end

    it "should set end column on a body section when end column is different from start column" do
      @veterinary_services_section.end_column.should_not be_nil
      @veterinary_services_section.end_column.should == '2'
    end

    it "should create two contributions for a body section containing a question and answer" do
      @food_storage_section.body.contributions.size.should == 2
    end

    it "should set the xml_id correctly on each contribution for the first body section" do
      @food_storage_question.xml_id.should == "S6CV0089P0-04896"
      @food_storage_answer.xml_id.should == "S6CV0089P0-04897"
    end

    it "should create the first contribution as a procedural contribution" do
      @food_storage_question.should be_an_instance_of(ProceduralContribution)
    end

    it "should create the second contribution as a member contribution" do
      @food_storage_answer.should be_an_instance_of(WrittenMemberContribution)
    end

    it "should set the member correctly on the member contribution" do
      @food_storage_answer.member_name.should == 'Mr. Gummer'
    end

    it "should set the text correctly for the first contribution" do
      @food_storage_question.text.should == "Mr. Canavan asked the Minister of Agriculture, Fisheries and Food what is his latest available information on the amount of surplus food stored <i>(a)</i> in the United Kingdom and <i>(b)</i> in the European Economic Community and the costs of storage."
    end

    it "should put all paragraphs of a member's answer in the text of a single Contribution" do
      @food_storage_answer.text.should == %Q[<p id="S6CV0089P0-04897">A note setting out the volume of United Kingdom and Community</p>] +
          %Q[<p id="S6CV0089P0-04898">The storage, handling and related costs of United Kingdom intervention </p>]
    end
  end


  describe "when parsing a Commons writtenanswers file that doesn't contain group or body elements" do
    before(:all) do
      file = 'commons_writtenanswers_not_in_groups_example.xml'

      source_file = mock_model(SourceFile, :volume => mock_model(Volume))
      
      @sitting = parse_hansard_file(Hansard::WrittenAnswersParser, data_file_path(file), data_file=nil, source_file)

      @sitting_type = CommonsWrittenAnswersSitting
      @sitting_date = Date.new(2003,05,07)
      @sitting_date_text = 'Wednesday 7 May 2003'
      @sitting_title = 'Written Answers to Questions'
      @sitting_start_column = '679W'
      @sitting_end_column = '682W'
      @treasury_group = @sitting.groups.first
      @home_group = @sitting.groups[1]

      @employment_section = @treasury_group.sections[0]

      @employment_question = @employment_section.body.contributions[0]
      @employment_answer = @employment_section.body.contributions[1]

      @child_tax_credit_section = @treasury_group.sections[1]

      @asylum_seekers_section = @home_group.sections[0]
    end

    it_should_behave_like "All sittings or written answers or written statements"

    it "should create the correct number of groups in written answers" do
      @sitting.groups.size.should == 2
    end

    it "should create WrittenAnswersGroup for a top level section" do
      @treasury_group.should be_an_instance_of(WrittenAnswersGroup)
    end

    it "should create a Section for each section under a top level section" do
      @employment_section.should be_an_instance_of(Section)
      @child_tax_credit_section.should be_an_instance_of(Section)
    end

    it "should each Section should have a body (equal to itself)" do
      @employment_section.body.should == @employment_section
      @child_tax_credit_section.body.should == @child_tax_credit_section
    end

    it 'should have only two contributions in a section with a single question and answer' do
      @employment_section.contributions.size.should == 2
    end

    it "should put all paragraphs of a member's answer in the text of a single Contribution" do
      @employment_answer.text.should == %Q[<p>The information requested falls within the responsibility of the National Statistician. I have asked him to reply.</p>] +
        %Q[<p><i>Letter from C. Mowl to Mr. Frank Field, dated 7 May 2003:</i></p>] +
        %Q[<quote>The Parliamentary Secretary, Lord Chancellor's Department has asked me to reply to your Question about Court Service staff numbers and cost.</quote>]
    end

    it 'should add ordered list element to member contribution text' do
      contribution = @child_tax_credit_section.contributions[1]
      contribution.should be_an_instance_of(WrittenMemberContribution)
      contribution.text.should == "<p>\nThe child tax credit was introduced on</p>" +
        "<ol>\n<li>10,153 facilities met targets which did not include a tolerance band;</li>\n</ol>" +
        "<ul>\n<li>0 facilities met targets which did include a tolerance band;</li>\n</ul>"

    end

    it 'should create the correct number of contributions for a section' do
      @asylum_seekers_section.contributions.size.should == 2
    end

    it 'should create procedural contribution for table inside paragraph element' do
      contribution = @asylum_seekers_section.contributions[1]
      contribution.column_range.should == '682W'
      contribution.should be_an_instance_of(WrittenMemberContribution)
      contribution.text.should == "<p>The table details the number of</p><table>\n<tr>\n<td></td>\n</tr>\n</table>"
    end
  end

  describe 'when parsing a Commons written answers file that doesnt contain group elements or grouping sections' do 
 
    before(:all) do
      file = 'commons_written_answers_no_groups.xml'
      source_file = mock_model(SourceFile, :volume => mock_model(Volume))
      @sitting = parse_hansard_file(Hansard::WrittenAnswersParser, data_file_path(file), data_file=nil, source_file)

      @sitting_type = CommonsWrittenAnswersSitting
      @sitting_date = Date.new(1909, 3, 1)
      @sitting_date_text = ''
      @sitting_title = 'QUESTIONS ANSWERED IN WRITING.'
      @sitting_start_column = '1223'
      @sitting_end_column = '1224'
      @dockyard_group = @sitting.groups[0]
    end
    
     it_should_behave_like "All sittings or written answers or written statements"
     
     it 'should create a group for each section' do 
       @sitting.groups.size.should == 4
     end
     
     it 'should create a group for the first section' do
       @dockyard_group.should be_an_instance_of(WrittenAnswersGroup)
     end
     
     it 'should create a section with group title duplicated' do
       @dockyard_group.sections.size.should == 1
       section = @dockyard_group.sections.first
       section.should be_an_instance_of(Section)
       section.title.should == 'Rosyth Dockyard.'
     end

     it 'should create contributions for a body element not inside a subsection' do
       body = @dockyard_group.sections.first.body
       body.contributions.size.should == 2
     end
     
  end

  describe "when parsing a Commons writtenanswers file that doesn't contain group elements" do
    before(:all) do
      file = 'commons_writtenanswers_with_sections_at_top_level.xml'
      source_file = mock_model(SourceFile, :volume => mock_model(Volume))
      @sitting = parse_hansard_file(Hansard::WrittenAnswersParser, data_file_path(file), data_file=nil, source_file)

      @sitting_type = CommonsWrittenAnswersSitting
      @sitting_date = Date.new(1985,12,16)
      @sitting_date_text = 'Monday 16 December 1985'
      @sitting_title = 'Written Answers to Questions'
      @sitting_start_column = '1'
      @sitting_end_column = '1'
      @first_group   = @sitting.groups.first
      @first_section = @first_group.sections.first
      @first_body    = @first_section.sections.first
    end

    it "should create the correct number groups for a sitting" do
      @sitting.groups.size.should == 1
    end

    it "should set the title correctly for a question group" do
      @first_group.title.should == 'AGRICULTURE, FISHERIES AND FOOD'
    end

    it "should create the correct number of sections for a question group" do
      @first_group.sections.size.should == 2
    end

    it "should set the title correctly for a question section" do
      @first_section.title.should == 'Food Storage'
    end

    it "should set model type to Section for a question section" do
      @first_section.should be_an_instance_of(Section)
    end

    it "should create a body section belonging to a question section" do
      @first_section.sections.size.should == 1
      @first_body.should be_an_instance_of(WrittenAnswersBody)
    end

    it_should_behave_like "All sittings or written answers or written statements"
  end

  describe "when parsing a Commons writtenanswers that has a body element not inside a subsection" do
    before(:all) do
      file = 'commons_writtenanswers_with_body_not_in_subsection.xml'
      source_file = mock_model(SourceFile, :volume => mock_model(Volume))
      @sitting = parse_hansard_file(Hansard::WrittenAnswersParser, data_file_path(file), data_file=nil, source_file)
      @sitting_type = CommonsWrittenAnswersSitting
      @sitting_date = Date.new(1968,12,02)
      @sitting_date_text = 'Monday, 2nd December, 1968'
      @sitting_title = 'WRITTEN ANSWERS TO QUESTIONS'
      @sitting_start_column = '221'
      @sitting_end_column = '354'
      @land_registry_group = @sitting.groups[0]
    end

    it 'should create a group for a section not in a group' do
      @land_registry_group.should be_an_instance_of(WrittenAnswersGroup)
    end

    it 'should create a section with group title duplicated for a body element not inside a subsection' do
      @land_registry_group.sections.size.should == 1
      section = @land_registry_group.sections.first
      section.should be_an_instance_of(Section)
      section.title.should == 'LAND REGISTRY'
    end

    it 'should create contributions for a body element not inside a subsection' do
      body = @land_registry_group.sections.first.body
      body.contributions.size.should == 8
    end
  end

  describe "when parsing a Commons writtenanswers that has a section outside its grouping section" do
    before(:all) do
      file = 'commons_writtenanswers_sections_not_nested_in_grouping_section.xml'
      source_file = mock_model(SourceFile, :volume => mock_model(Volume))
      @sitting = parse_hansard_file(Hansard::WrittenAnswersParser, data_file_path(file), data_file=nil, source_file)

      @sitting_type = CommonsWrittenAnswersSitting
      @sitting_date = Date.new(2003,05,06)
      @sitting_date_text = 'Tuesday 6 May 2003'
      @sitting_title = 'Written Answers to Questions'
      @sitting_start_column = '535W'
      @sitting_end_column = '535W'
      @prime_minsters_group = @sitting.groups[0]
      @foreign_group = @sitting.groups[1]
    end

    it_should_behave_like "All sittings or written answers or written statements"

    it 'should create correct number of groups' do
      @sitting.groups.size.should == 2
    end

    it 'should add a section to the previous group if the section is top level and has paragraphs directly after its title' do
      @prime_minsters_group.sections.size.should == 4
      @prime_minsters_group.title.should == 'PRIME MINISTER'
      @prime_minsters_group.sections[0].title.should == 'Energy Policy'
      @komos_section = @prime_minsters_group.sections[1]
      @komos_section.title.should == 'KOMOS'
      @komos_section.sections.size.should == 0
      @prime_minsters_group.sections[2].title.should == 'Meetings'
      @prime_minsters_group.sections[3].title.should == 'Ministerial Responsibility'
    end

    it 'should create new group correctly after sections that were outside their grouping section' do
      @foreign_group.sections.size.should == 1
      @foreign_group.title.should == 'FOREIGN AND COMMONWEALTH AFFAIRS'
      @foreign_group.sections[0].title.should == 'Zimbabwe'
    end
  end

  describe "when creating a sitting" do
    it 'should create the sitting on the date in the filename rather than the date from the xml if the two differ' do
      source_file = mock_model(SourceFile, :volume => mock_model(Volume))
      parser = Hansard::WrittenAnswersParser.new(data_file_path('commons_written_answers_1889_08_21.xml'), nil, source_file)
      CommonsWrittenAnswersSitting.should_receive(:new).with({:date=>"1889-08-21",
                                                       :date_text=>"Wednesday, 21st August, 1889.",
                                                       :title=>"Written Answers to Questions",
                                                       :start_column=>nil,
                                                       :data_file => nil}).and_return(mock_model(Sitting, :null_object => true))
      parser.parse
    end
  end
  
  describe 'when handling anchor ids' do 

    before do 
      source_file = mock_model(SourceFile, :name => "S6CV0417P1")
      data_file = mock_model(DataFile, :source_file => source_file, 
                                       :name => 'commons_written_answers_1889_08_21.xml')
      @parser = Hansard::WrittenAnswersParser.new(data_file_path(data_file.name), data_file, source_file)
      @parser.stub!(:sitting).and_return(mock_model(Sitting, :data_file => data_file, 
                                                             :type_abbreviation => 'WA',
                                                             :short_date => '20040212'))
    end

    it_should_behave_like "All parsers"
  
  end

end
