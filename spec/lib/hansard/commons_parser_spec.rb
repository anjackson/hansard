require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::CommonsParser do

  def H text
    Hpricot text
  end

  describe 'when handling member contribution containing house divided text' do
    
    before do 
      @parser = Hansard::CommonsParser.new ''
      @section = mock_model(Section)
      @section.stub!(:add_contribution)
      @parser.stub!(:anchor_id)
      @contribution = mock_model(ProceduralContribution)
    end
    
    def expect_member_contribution_text text, expected
      element = H(text).at('p')
      @parser.stub!(:create_house_divided_contribution).and_return @contribution
      @parser.stub!(:add_division_after_divided_text)
      member_contribution = @parser.handle_member_contribution element, @section
      member_contribution.text.should == expected
    end
    
    it 'should create a member contribution with the text before the House Divided text' do
      html = %Q|<p id="S5CV0503P0-01230"><member>Mr. Lloyd</member><membercontribution>: I was<lb/>
                  The House divided: Ayes, 270; Noes, 300.</membercontribution></p>|
      expect_member_contribution_text(html, ': I was')
    end

    it 'should create a member contribution with the text before the House Divided text if that text is in italics' do
      html = %Q|<p id="S5CV0597P0-02927"><member>Mr. Douglas Jay <memberconstituency>(Battersea, North)</memberconstituency></member><membercontribution>: Since <lb/>
  <i>The House divided:</i> Ayes 218, Noes 171.<lb/></membercontribution></p>|
      expect_member_contribution_text(html, ': Since ')
    end
  end

  describe 'when handling speaker in chair' do
    it 'should recognize mr speaker in chair' do
      parser = Hansard::CommonsParser.new ''
      parser.is_person_in_chair?('[MR. SPEAKER in the Chair.]').should be_true
    end

    it 'should recognize mrspeaker in chair' do
      parser = Hansard::CommonsParser.new ''
      parser.is_person_in_chair?('[MR.SPEAKER in the Chair.]').should be_true
    end

    it 'should recognize "[Mr. SPEAKER <i>in the Chair</i>]"' do
      parser = Hansard::CommonsParser.new ''
      parser.is_person_in_chair?('[Mr. SPEAKER <i>in the Chair</i>]').should be_true
    end
  end

  describe "when handling the contents of a debate tag" do
    before do
      file = data_file_path('housecommons_empty.xml')
      @parser = Hansard::CommonsParser.new(file)
      @sitting = mock_model(Sitting, :text => nil)
    end

  end

  describe 'when handling oral questions sections ' do
   
    before do
      file = data_file_path('housecommons_empty.xml')
      @parser = Hansard::CommonsParser.new(file)
      @mock_section = mock_model(Section, :null_object => true)
      @parser.stub!(:create_section).and_return(@mock_section)
      @oral_questions = @mock_section
      @sitting = mock_model(Sitting)
    end

    it "should make a question contribution for a 'p' tag with a 'membercontribution' tag inside" do
      section = Hpricot('<section>
      <title>"Hyacinth" and "Minerva"&#x2014;Time Spent on Repairs.</title>
      <p id="S4V0126P0-00280"><member>COLONEL DENNY <memberconstituency>(Kilmarnock Burghs)</memberconstituency></member><membercontribution>: To ask the Secretary to the Admiralty what amount of time has been incurred in overhauls on the "Hyacinth" and "Minerva" respectively since the date of handing over of the former by the builders; how much of the time spent in these overhauls has been expended during the financial year ending 31st March, 1903; and what has been the mileage run on trials and commissions respectively by these ships since the date of intimation to the Boiler Committee that these vessels were ready for comparative trials.<lb/>
      (<i>Answered by Mr. Arnold-Forster.</i>) The "Hyacinth" has been in dockyard hands for about nineteen months, and the "Minerva" for about eleven and a half months since the date when the "Hyacinth" was first commissioned&#x2014;viz., 3rd September, 1900. During the financial year ending 31st March, 1903, the time thus occupied was twenty-three weeks in the case of the "Hyacinth," and twelve weeks in the case of the "Minerva." The "Hyacinth" has run 8,219 knots, and the "Minerva" 9,142 knots on trials since the date of the intimation to the Boiler Committee that the ships were ready for trials, and the total distance run whilst in commission since the 1st January 1901, has been:&#x2014;"Hyacinth," 16,831 knots; "Minerva," 36,660 knots.</membercontribution></p>
      </section>')
      @parser.should_receive(:handle_question_contribution)
      @parser.handle_oral_questions_section section, @oral_questions, @sitting
    end
    
    it 'should handle a division as a division passing the oral questions section if there is a division handler' do 
      @parser.stub!(:division_handler).and_return(mock('division handler'))
      section = Hpricot('<section><division></division></section>')
      division = section.at('division')
      section = section.at('section')
      @parser.should_receive(:handle_division).with(division, @mock_section)
      @parser.handle_oral_questions_section section, @oral_questions, @sitting
    end
    
    it 'should handle a division as a placeholder passing the oral questions section if there is no division handler' do 
      @parser.stub!(:division_handler).and_return(nil)
      section = Hpricot('<section><division></division></section>')
      division = section.at('division')
      section = section.at('section')
      @parser.should_receive(:handle_unparsed_division).with(division, @mock_section)
      @parser.handle_oral_questions_section section, @oral_questions, @sitting
    end
  end
  
  describe 'when handling an oral question section' do 
    
    before do
      file = data_file_path('housecommons_empty.xml')
      @parser = Hansard::CommonsParser.new(file)
      @mock_section = mock_model(Section, :null_object => true)
      @parser.stub!(:create_section).and_return(@mock_section)
      @oral_questions = @mock_section
      @sitting = mock_model(Sitting)
    end
    
    it 'should handle a division, passing the oral question section' do 
      section = Hpricot('<section><division></division></section>')
      division = section.at('division')
      section = section.at('section')
      @parser.should_receive(:handle_division).with(division, @mock_section)
      @parser.handle_oral_question_section section, @oral_questions
    end
    
    it 'should handle quote elements as question contributions' do 
      section_text = "<section>
      <title>Planning Appeal, Saffron Walden</title>
      <p id=\"S5CV0637P0-00718\"><i>Following is the information:</i></p>
      <quote>Extract from decision letter dated 17th September, 1959:</quote>
      </section>"
      section = Hpricot(section_text).at('section')
      quote = section.at('quote')
      @parser.stub!(:handle_question_contribution)
      @parser.should_receive(:handle_question_contribution).with(quote, @mock_section)
      @parser.handle_oral_question_section section, @oral_questions
    end
    
    it 'should handle a division as a division passing the oral questions section if there is a division handler' do 
      @parser.stub!(:division_handler).and_return(mock('division handler'))
      section = Hpricot('<section><division></division></section>')
      division = section.at('division')
      section = section.at('section')
      @parser.should_receive(:handle_division).with(division, @mock_section)
      @parser.handle_oral_question_section section, @oral_questions
    end
    
    it 'should handle a division as a placeholder passing the oral questions section if there is no division handler' do 
      @parser.stub!(:division_handler).and_return(nil)
      section = Hpricot('<section><division></division></section>')
      division = section.at('division')
      section = section.at('section')
      @parser.should_receive(:handle_unparsed_division).with(division, @mock_section)
      @parser.handle_oral_question_section section, @oral_questions
    end
    
  end

  describe Hansard::CommonsParser do
    before(:all) do
  
      @sitting_type = HouseOfCommonsSitting
      @sitting_date = Date.new(1985,12,16)
      @sitting_date_text = 'Monday 16 December 1985'
      @sitting_title = 'House of Commons'
      @sitting_start_column = '1'
      @sitting_end_column = '745'
      @sitting_chairman = 'MR. SPEAKER'
      @volume = mock_model(Volume)
      source_file = SourceFile.new(:volume => @volume, :name => 'S6CV0417P1')
      data_file = mock_model(DataFile, :name => '')
      file = 'housecommons_example.xml'
      @sitting = parse_hansard_file(Hansard::CommonsParser, data_file_path(file), data_file, source_file)
      @sitting.stub!(:populate_members)
      @sitting.save!
  
      @first_section = @sitting.debates.sections.first
      @oral_questions = @sitting.debates.oral_questions
      @first_questions_section = @oral_questions.sections.first
      @first_question = @oral_questions.sections.first.questions.first
      @first_question_contribution = @first_question.contributions.first
      @second_question_contribution = @first_question.contributions[1]
  
      @third_section = @sitting.debates.sections[2]
      @third_section_second_contribution = @third_section.contributions[1]
  
      @seventh_section = @sitting.debates.sections[6]
      @seventh_section_first_contribution = @seventh_section.contributions.first
      @seventh_section_second_contribution = @seventh_section.contributions[1]
  
      @eighth_section = @sitting.debates.sections[7]
      @eighth_section_first_contribution = @eighth_section.contributions.first
      @eighth_section_second_contribution = @eighth_section.contributions[1]
  
      @orders_of_the_day = @sitting.debates.sections[12]
  
      contributions = @sitting.debates.sections[14].sections[0].contributions
      @division_placeholder = contributions[contributions.size - 3]
      @division = @division_placeholder.division
  
      count = @sitting.debates.sections.size
      @quote = @sitting.debates.sections[count - 2].contributions[1]
      @last_procedural_contribution = @sitting.debates.sections.last.contributions.last
      @first_contribution = @sitting.contributions.first
    end
    
    
    it 'should create sitting with association to a volume' do
      @sitting.volume.should == @volume
    end
  
    it "should create a sitting whose sections all have a start_column" do
      @sitting.all_sections.each do |section|
        section.start_column.should_not be_nil
      end
    end
  
    it 'should add a procedural note for an italics element after a member element' do
      contribution = @sitting.debates.sections.last.contributions.first
      contribution.xml_id.should == 'S6CV0089P0-01275' # that's the one!
      contribution.procedural_note.should == "<i>(seated and covered)</i>"
    end
  
    it 'should add a procedural contribution for an ul element after a p element' do
      contribution = @sitting.debates.sections.last.contributions[2]
      contribution.should_not be_nil
      contribution.should be_an_instance_of(ProceduralContribution)
      contribution.text.should == %Q[<ul>\n<li>(f), in line 6, leave out "two" and insert "five".</li>\n<li>(b), in line 6, leave out "two years" and insert "one year".</li>\n</ul>]
    end
  
    it 'should add a procedural contribution for an ol element after a p element' do
      count = @sitting.debates.sections.size
      contribution = @sitting.debates.sections[count - 2].contributions[2]
      contribution.should_not be_nil
      contribution.should be_an_instance_of(ProceduralContribution)
      contribution.text.should == %Q[<ol>\n<li>1. Paragraphs 4 and 5 of the order shall be omitted.</li>\n<li>2. Proceedings on consideration and Third Reading shall (so far as not previously concluded) be brought to a conclusion:</li>\n</ol>]
    end
  
    it 'should add text preceding member element to question contribution member text' do
      question = @oral_questions.sections.last.sections.last.contributions.last
      question.member_name.should == "The Parliamentary Under-Secretary of State for Health (Dr. Stephen Ladyman)"
    end
  
    it 'should set the column property on the first element following an column tag within the orders of the day' do
      count = @sitting.debates.sections.size
      section = @sitting.debates.sections[count - 3].sections[0]
      section.start_column.should == '1027'
    end
  
    it 'should parse a quote element' do
      @quote.should_not be_nil
    end
  
    it 'should create quote contribution for a quote element' do
      @quote.should be_an_instance_of(QuoteContribution)
    end
  
    it 'should set the text for a quote correctly' do
      @quote.text.should == "That Sir Antony Buck and Mr. Robert Key be discharged from the Select Committee on the Armed Forces Bill and that Mr. Tony Baldry and Mr. Nicholas Soames be added to the Committee.&#x2014;<i>(Mr. Maude.]</i>"
    end
  
    it 'should set the column range for a quote correctly' do
      @quote.column_range.should == '744'
    end
  
    it 'should create first section in debates' do
      @first_section.should_not be_nil
      @first_section.should be_an_instance_of(Section)
    end
  
    it 'should set text on first section in debates' do
      @first_section.contributions[0].text.should == '[MR. SPEAKER <i>in the Chair</i>]'
    end
  
    it 'should set style attributes on a contribution' do
      @first_section.contributions[0].style.should == "align=center"
    end
  
    it 'should set title on first section in debates' do
      @first_section.title.should == 'PRAYERS'
    end
  
    it 'should set start column on first section in debates' do
      @first_section.start_column.should == '1'
    end
  
    it 'should set xml id on first section in debates' do
      @first_section.contributions[0].xml_id.should == 'S6CV0089P0-00361'
    end
  
    it 'should set debates parent on first section in debates' do
      @first_section.parent_section_id.should == @sitting.debates.id
      @first_section.parent_section.should == @sitting.debates
    end
  
    it 'should create oral questions' do
      @oral_questions.should_not be_nil
      @oral_questions.should be_an_instance_of(OralQuestions)
    end
  
    it 'should set debates parent on oral questions' do
      @oral_questions.parent_section_id.should == @sitting.debates.id
      @oral_questions.parent_section.should == @sitting.debates
    end
  
    it 'should set title on oral questions' do
      @oral_questions.title.should == 'Oral Answers to Questions'
    end
  
    it 'should set first section on oral questions' do
      @first_questions_section.should_not be_nil
      @first_questions_section.should be_an_instance_of(OralQuestionsSection)
    end
  
    it 'should set parent on first oral questions section' do
      @first_questions_section.parent_section_id.should == @oral_questions.id
      @first_questions_section.parent_section.should == @oral_questions
    end
  
    it 'should set title on first oral question section' do
      @first_questions_section.title.should == 'ENERGY'
    end
  
    it 'should set first oral question' do
      @first_question.should_not be_nil
      @first_question.should be_an_instance_of(OralQuestionSection)
    end
  
    it 'should set parent section on first oral question' do
      @first_question.parent_section_id.should == @first_questions_section.id
      @first_question.parent_section.should == @first_questions_section
    end
  
    it 'should set title on first oral question' do
      @first_question.title.should == 'Scottish Coalfield'
    end
  
    it 'should set first oral question contribution' do
      @first_question_contribution.should_not be_nil
      @first_question_contribution.should be_an_instance_of(MemberContribution)
    end
  
    it 'should set parent section on first oral question contribution' do
      @first_question_contribution.section_id.should == @first_question.id
      @first_question_contribution.section.should == @first_question
    end
  
    it 'should set xml_id on first oral question contribution' do
      @first_question_contribution.xml_id.should == 'S6CV0089P0-00362'
    end
  
    it 'should set oral question number on first oral question contribution' do
      @first_question_contribution.question_no.should == '1.'
    end
  
    it 'should set a oral question number when number is formated as Q1.' do
      question = @oral_questions.sections.last.sections.first.contributions.first
      question.question_no.should == 'Q1.'
    end
  
    it 'should set member name correctly when member element contains member constituency for an oral question' do
      question = @oral_questions.sections.last.sections.first.contributions.first
      question.member_name.should == 'Mr. Frank Field'
    end
  
    it 'should set member constituency when member element contains member constituency for an oral question' do
      question = @oral_questions.sections.last.sections.first.contributions.first
      question.constituency_name.should == 'Birkenhead'
    end
  
    it "should add an introduction procedural contribution to an oralquestions section that has a 'p' tag within it" do
      count = @oral_questions.sections.size
      section = @oral_questions.sections[count - 2]
      section.title.should == "SCOTLAND"
      section.introduction.should_not be_nil
      section.introduction.should be_an_instance_of(ProceduralContribution)
      section.introduction.text.should == "<i>The Secretary of State was asked</i>&#x2014;"
    end
  
    it 'should set member on first oral question contribution' do
      @first_question_contribution.member_name.should == 'Mr. Douglas'
    end
  
    it 'should set member contribution on first oral question contribution' do
      @first_question_contribution.member_contribution.should == 'asked the Secretary of State for Energy if he will make a statement on visits by Ministers in his Department to pits in the Scottish coalfield.'
    end
  
    it 'should set column range on first oral question contribution' do
      @first_question_contribution.column_range.should == '1'
    end
  
    it 'should set second oral question contribution' do
      @second_question_contribution.should_not be_nil
      @second_question_contribution.should be_an_instance_of(MemberContribution)
    end
  
    it 'should set parent section on second oral question contribution' do
      @second_question_contribution.section_id.should == @first_question.id
      @second_question_contribution.section.should == @first_question
    end
  
    it 'should set xml_id on second oral question contribution' do
      @second_question_contribution.xml_id.should == 'S6CV0089P0-00363'
    end
  
    it 'should not set oral question number on second oral question contribution' do
      @second_question_contribution.question_no.should be_nil
    end
  
    it 'should set member on second oral question contribution' do
      @second_question_contribution.member_name.should == 'The Parliamentary Under-Secretary of State for Energy (Mr. David Hunt)'
    end
  
    it 'should set constituency correctly on second oral question contribution' do
      @second_question_contribution.constituency_name.should be_nil
    end
  
    it 'should set member contribution on second oral question contribution' do
      @second_question_contribution.member_contribution.should == ': I was extremely impressed during my recent visit to the Scottish coalfield to hear of the measures being taken to reduce costs and improve productivity.'
    end
  
    it 'should set column range on second oral question contribution' do
      @second_question_contribution.column_range.should == '1'
    end
  
    it 'should set member on a oral question contribution containing <lb>' do
      question = @oral_questions.sections.first.questions.last
      question.contributions.first.member_name.should == 'Mr. Hilton'
    end
  
    it 'should set member on a oral question with two question numbers' do
      question = @oral_questions.sections.first.questions.last
      question.contributions.first.question_no.should == '12 and 13.'
    end
  
    it 'should set member contribution on a oral question contribution containing <lb>' do
      question = @oral_questions.sections.first.questions.last
      question.contributions.first.member_contribution.should == "asked the Minister of Agriculture, Fisheries and Food (1) how many outbreaks of fowl pest have been confirmed in Norfolk during the past three months; how this number compares with outbreaks in previous years; and what new measures are proposed to reduce the outbreaks of this disease;<lb/>\n<col>596</col>\n(2) how much has been paid in compensation in Norfolk in respect of fowl pest during the past three months; and what is the largest amount paid to any one breeder during the same period."
    end
  
    it 'should create third section in debates' do
      @third_section.should_not be_nil
      @third_section.should be_an_instance_of(Section)
    end
  
    it 'should create time contribution for a p element containing the text "3.30 pm"' do
      @third_section.contributions[0].should be_an_instance_of(TimeContribution)
    end
  
    it 'should set xml_id correctly on a time contribution instance' do
      @third_section.contributions[0].xml_id.should == 'S6CV0089P0-00525'
    end
  
    it 'should set text correctly on time contribution for a p element containing the text "3.30 pm"' do
      @third_section.contributions[0].text.should == '3.30 pm'
    end
  
    it 'should set time correctly on time contribution for a p element containing the text "3.30 pm"' do
      @third_section.contributions[0].time.strftime('%H:%M:%S').should == '15:30:00'
    end
  
    it 'should set column range correctly on a time contribution' do
      @third_section.contributions[0].column_range.should == '21'
    end
  
    it 'should set contribution parent correctly on a time contribution' do
      @third_section.contributions[0].section_id.should == @third_section.id
      @third_section.contributions[0].section.should == @third_section
    end
  
    it 'should set title on third section in debates' do
      @third_section.title.should == 'Social Security White Paper'
    end
  
    it 'should set start column on third section in debates' do
      @third_section.start_column.should == '21'
    end
  
    it 'should set debates parent on third section in debates' do
      @third_section.parent_section_id.should == @sitting.debates.id
      @third_section.parent_section.should == @sitting.debates
    end
  
    it 'should set second (member) contribution on third section' do
      @third_section_second_contribution.should_not be_nil
      @third_section_second_contribution.should be_an_instance_of(MemberContribution)
    end
  
    it 'should set second (member) contribution xml id on third section' do
      @third_section_second_contribution.xml_id.should == 'S6CV0089P0-00526'
    end
  
    it 'should set second (member) contribution column range on third section' do
      @third_section_second_contribution.column_range.should == '21,22,23,24,25'
    end
  
    it 'should set second (member) contribution member on third section' do
      @third_section_second_contribution.member_name.should == 'The Secretary of State for Social Services (Mr. Norman Fowler)'
    end
  
    it 'should set second (member) contribution text on third section' do
      @third_section_second_contribution.text.should == %Q[: With permission, Mr. Speaker, I shall make a statement on the Social Security White Paper which I am publishing today.<lb/>\nIn June the Government published a Green Paper which set out in detail the case for change, the Government's objectives for social security and our proposals for achieving them. That Green Paper marked a further stage in the process of review and public consultation which began two years ago in the autumn of 1983.<lb/>\nThe Government have four main aims. We want to see a simpler system of social security which provides a better service to the public. By common consent, social security at present is too complex. There are some 30 benefits, each with separate and frequently conflicting rules of entitlement, and supplementary benefit alone requires almost 40,000 staff to administer it.<lb/>\nWe want to see more people looking forward to greater independence in retirement. Only half the work force currently have occupational pensions of their own. Our plans extend not only to occupational pensions but, for the first time, provide a new right to personal pensions.<lb/>\nWe want a system which is financially secure. As the Government Actuary's report, published with the White Paper, demonstrates, the future cost of the state earnings-related pension scheme will grow substantially&#x2014;at the same time as the ratio of contributors to pensioners worsens. The Government believe that this problem must be tackled now.<lb/>\nAbove all, we want to see more effective help going to those who most need it. More than half of those living on the lowest incomes today are in families with children. This includes both families where the parents are unemployed and low-income working families. Added to this people can still find themselves with less income in work than if they were unemployed. Others can find that a pay rise in work can actually make them worse off. The Government believe that urgent action is necessary to tackle these problems.<lb/>\nOne of the major priorities of the Government's proposals is to make better provision for low-income working families with children. Accordingly, we propose to abolish the present family income supplement and to introduce a new benefit, family credit.<lb/>\nFamily credit is designed to ensure that families with children will be better off in work. It will be based on take-home or net pay&#x2014;rather than gross earnings, as with family income supplement&#x2014;so that the worst effects of the poverty trap are eliminated.<lb/>\nWe expect that, compared with family income supplement, family credit will give help to an extra 200,000 families. In other words, twice as many low income families with children will benefit from the new scheme. Family credit will be paid through the pay packet, but it should be emphasised that child benefit will be paid in addition and that that payment will go, as now, direct to the mothers.<lb/>\nWe also intend to bring extra support to families who are not in work. This will be achieved through the new income support scheme. A family premium&#x2014;a special higher level of benefit&#x2014;will be paid on top of the basic\n<col>22</col>\nincome support rate and on top of the rates for individual children. One of the groups who will most gain from this change will be unemployed families with children.<lb/>\nThe income support scheme will replace supplementary benefit. The regular extra payments now made on the basis of detailed individual assessment will be absorbed into the main rates of benefit. As well as a premium for families with children, there will be an additional premium for lone parents and premiums for pensioners and the long-term sick and disabled. At the same time, the capital rule, which at present is an inflexible &#x00A3;3,000 cut off, will be substantiall eased, and we will also ease the earnings rules for lone parents, disabled people and long-term unemployed families.<lb/>\nWhile the broad pattern of income support will remain as set out in the Green Paper, we have modified our proposals in the light of consultations in two significant ways.<lb/>\nFirst, the income support rate will still be based on age divisions at 18 and 25 for single people. However, in order to help young families with children in particular, we now intend to have the same rate for all couples over 18.<lb/>\nSecondly, we intend to increase the help for families with more than one disabled child. The Green Paper proposed a double family premium where there was one disabled child or more. We have now decided to pay the extra premium for each disabled child in a household.<lb/>\nThis last change will reinforce the special attention which we give to disabled people in our proposals. They will benefit from the premium in income support and from a higher earnings disregard. Overall, disabled people on low incomes will benefit significantly from the proposals.<lb/>\nHowever well designed the income support scheme may be, it cannot anticipate every special or emergency need. These needs will be dealt with by the social fund.<lb/>\nInstead of the present small universal maternity and death grants&#x2014;which have both remained at the same value for over 15 years&#x2014;proper help will be available from the fund to all low income families, not just those on supplementary benefit. The grant for funeral expenses will ensure that the full cost of the funeral can be met, and it is planned that the maternity grant should be set at about &#x00A3;75. Grants will also be given for community care purposes; for example, to help someone leaving a long-stay hospital. In addition, the fund will provide loans to help claimants cope with items other than normal weekly needs.<lb/>\nThe main structure of our housing benefit proposals has been acknowledged as an important simplification of the scheme. Treating employed and unemployed people alike, and so getting rid of two separate systems in housing benefit, has been particularly welcomed.<lb/>\nWe shall go ahead with this, but I intend, in response to consultations, to make two significant changes to the Green Paper proposals. First, I recognise the anxieties expressed about the effect of a single taper for rent and rates on owner-occupiers, particularly pensioners. I also recognise the concern of local authorities that a single taper would create administrative difficulties for them. We shall therefore keep separate tapers for rent and rates, and this will still be a substantial simplification compared with the six tapers in the present system.<lb/>\nSecondly, although the general power to run local housing benefit schemes will be ended, local authorities will retain their power to grant extra benefit to individual\n<image src=\"S6CV0089P0I0021\"/>\n<col>23</col>\nclaimants in exceptional circumstances. I have also decided that they should retain their power to give special treatment to war pensioners.<lb/>\nAs we made clear in the Green Paper, we believe that the basis on which help is provided with rates needs to be changed. At present, around 7 million householders receive help with some or all of their rates bill, and up to 3 million householders pay no rates. We stand by the principle that everyone should make a contribution towards the cost of his local services. The White Paper therefore reaffirms the proposal that everyone should pay at least 20 per cent. of his rates, but the proposals which my right hon. Friend the Secretary of State for the Environment will be bringing forward shortly on the reform of local taxation may affect the way this contribution is made.<lb/>\nThe Government will be carrying forward the proposals for directing widows' benefits to those who need them most and for making maternity allowance more flexible and more closely related to recent work. The new lump sum payment of &#x00A3;1,000 to widows will be tax-free and will be ignored when considering help with funeral expenses. The White Paper also proposes that maternity allowances, like statutory sick pay, should be paid through employers, and a consultation document will be published shortly on this.<lb/>\nOn timing, we shall move to the first April uprating in 1987 and at that time we shall introduce other changes like statutory maternity allowance and the new system of help with maternity and funeral costs. The main structural changes to income-related benefits and the other elements of the social fund will be introduced in April 1988. This recognises the arguments of employers and local authorities that the timetable must allow them to make proper preparations.<lb/>\nAs far as income-related benefits are concerned, a technical annex is published with the White Paper. The figures show the possible distributional effects of the changes, but these can be no more than illustrative. The actual position at the time of change will depend, among other things, on the exact benefit rates decided for April 1988, and the illustrative figures take no account of any changes resulting from the reform of rates.<lb/>\nAs far as pensions policy is concerned, the Government Actuary's report, published with the White Paper, shows that if no action is taken, total pension costs will increase from under &#x00A3;15&#x00B7;5 billion to nearly &#x00A3;49 billion a year provided that the basic pension is uprated by prices. If, as some urge, the basic pension is uprated in line with earnings, the total pension cost increases to nearly &#x00A3;73 billion, which would require a national insurance contribution of 27&#x00B7;5 per cent. The cost of SERPS alone will increase from barely &#x00A3;200 million today to &#x00A3;25&#x00B7;5 billion.<lb/>\nThe Government cannot ignore the vast pension bill which is being handed down to our children. In the consultation a number of important organisations recognised that case but argued that, rather than completely replacing SERPS, the costs could be reduced by modifying its provisions. In testing whether a policy of modifying SERPS would be acceptable, the Government have two major objectives. First, we want to see the future cost of SERPS substantially reduced. Secondly, and even more fundamentally, we want to see many more people\n<col>24</col>\nwith their own pension. It is on the basis that both of those objectives can be achieved that the Government are prepared to change the proposals from those put forward in the Green Paper.<lb/>\nThe Government propose to modify the scheme so that costs in the next century can be afforded. As with the Green Paper proposals, the Government recognise the particular needs of those nearest retirement. The SERPS changes will not affect anyone retiring this century, nor anyone widowed this century. There will also be a transitional period as the new scheme comes into effect fully in 2010. The basic pension is entirely unaffected by the proposals, and we will continue fully to protect its value.<lb/>\nThe changes to SERPS are that occupational schemes contracted out of the state scheme should be responsible for inflation-proofing guaranteed minimum pensions in payment up to 3 per cent. a year; SERPS pensions should be based on a lifetime's earnings, not on the best 20 years as now, but special protection will be built in for women who have breaks in work to bring up families and for those who become disabled and people looking after them; SERPS pensions should be calculated on 20 per cent. of earnings rather than 25 per cent.; and widows and widowers over 65 should be allowed to inherit half their spouse's SERPS rights, rather than the full amount as now.<lb/>\nHowever, policy on SERPS is only part of the Government's pensions strategy. Our central aim is to provide many more people with their own pension. The White Paper puts forward a six point plan to achieve that. First, a special incentive will be given to encourage the setting up a new occupational pension schemes. That will consist of a reduction, or rebate, on national insurance contributions. An extra 2 per cent. rebate will be added to the existing rebate, making a total incentive of almost 8 per cent. That special rebate will last for five years.<lb/>\nSecondly, for the first time, every employee will be able to take a personal pension, whether or not his employer runs an occupational scheme. The holder of a personal pension will also receive the special national insurance incentive and his contributions will qualify for tax relief.<lb/>\nThirdly, for the first time, employers will be able to contract out of the state scheme by guaranteeing a level of contribution to an occupational scheme&#x2014;rather than accept the unlimited liability of promising a \"final salary\" pension. Those new arrangements will also open the way for more industry-wide schemes.<lb/>\nFourthly, building societies, banks and unit trusts will be able to provide personal pension savings schemes, as well as group schemes.<lb/>\nFifthly, all members of occupational pension schemes will in future have the right to pay additional voluntary contributions in order to boost their income in retirement.<lb/>\nSixthly, people with personal pensions will be fully covered by the new investor protection arrangements to be made for all financial services.<lb/>\nThe changes build on top of the reforms introduced by the Social Security Act 1985 which protect the rights of early leavers. The White Paper proposes that that protection will be extended to all members of schemes leaving after two years rather than five years, as now. Anyone changing jobs will be able to transfer all his rights into a personal pension.<lb/>\nThe effect of the White Paper proposals will be to direct substantially more help to low income families with\n<image src=\"S6CV0089P0I0022\"/>\n<col>25</col>\nchildren, and to provide more help for disabled people on low incomes. We will take new steps to increase the spread of occupational pensions and give everyone the right to have a personal pension. We will provide a simpler and more effective benefit structure, and have now embarked on the biggest computer project of its kind in Western Europe.<lb/>\nFollowing the White Paper, the Government will introduce comprehensive legislation early in the new year. The aim will be to achieve a modern social security system directing help where that help is needed.]
    end
  
    it 'should set second (member) contribution parent on third section' do
      @third_section_second_contribution.section_id.should == @third_section.id
      @third_section_second_contribution.section.should == @third_section
    end
  
    it 'should set contribution column range when col element appears directly under secction element' do
      @third_section.contributions[3].column_range.should == '27'
    end
  
    it 'should create time contribution for a time stamp paragraph containing middle dot (&#x00B7;)' do
      @seventh_section_first_contribution.should be_an_instance_of(TimeContribution)
    end
  
    it 'should add member constituency to contribution if constituency is present' do
      @seventh_section_second_contribution.member_suffix.should == '(Workington)'
      @seventh_section_second_contribution.constituency_name.should == 'Workington'
    end
  
    it 'should create list of columns in column range when contribution text contains col element' do
      @seventh_section_second_contribution.column_range.should == '47,48'
    end
  
    it 'should create eighth section in debates' do
      @eighth_section.should_not be_nil
      @eighth_section.should be_an_instance_of(Section)
    end
  
    it 'should set title on eighth section in debates' do
      @eighth_section.title.should == 'SCOTTISH AFFAIRS'
    end
  
    it 'should set start column on eighth section in debates' do
      @eighth_section.start_column.should == '48'
    end
  
    it 'should set debates parent on eighth section in debates' do
      @eighth_section.parent_section_id.should == @sitting.debates.id
      @eighth_section.parent_section.should == @sitting.debates
    end
  
    it 'should set first (procedural) contribution on eighth section' do
      @eighth_section_first_contribution.should_not be_nil
      @eighth_section_first_contribution.should be_an_instance_of(ProceduralContribution)
    end
  
    it 'should set first (procedural) contribution text on eighth section' do
      @eighth_section_first_contribution.text.should == '<i>Ordered,</i>'
    end
  
    it 'should set first (procedural) contribution xml id on eighth section' do
      @eighth_section_first_contribution.xml_id.should == 'S6CV0089P0-00671'
    end
  
    it 'should set first (procedural) contribution column range on eighth section' do
      @eighth_section_first_contribution.column_range.should == '48'
    end
  
    it 'should set first (procedural) contribution parent on eighth section' do
      @eighth_section_first_contribution.section_id.should == @eighth_section.id
      @eighth_section_first_contribution.section.should == @eighth_section
    end
  
    it 'should set second (procedural) contribution on eighth section' do
      @eighth_section_second_contribution.should_not be_nil
      @eighth_section_second_contribution.should be_an_instance_of(ProceduralContribution)
    end
  
    it 'should set second (procedural) contribution xml id on eighth section' do
      @eighth_section_second_contribution.xml_id.should == 'S6CV0089P0-00672'
    end
  
    it 'should set second (procedural) contribution column range on eighth section' do
      @eighth_section_second_contribution.column_range.should == '48'
    end
  
    it 'should set second (procedural) contribution text on eighth section' do
      @eighth_section_second_contribution.text.should == 'That the matter of the recommendations of the Scottish Tertiary Education Advisory Council concerning higher education in Scotland, being a matter relating exclusively to Scotland, be referred to the Scottish Grand Committee for its consideration.&#x2014;[Mr. <i>Peter Lloyd.</i>]'
    end
  
    it 'should set second (procedural) contribution parent on eighth section' do
      @eighth_section_second_contribution.section_id.should == @eighth_section.id
      @eighth_section_second_contribution.section.should == @eighth_section
    end
  
    it "should set contribution to ProceduralContribution when there's no member contribution" do
      @sitting.debates.sections[9].contributions.last.should be_an_instance_of(ProceduralContribution)
    end
  
    it 'should set contribution text when contribution contains italics element' do
      text = "<i>It being Seven o'clock, the proceedings lapsed, pursuant to Standing Order No. 6 (Arrangement of public business).</i>"
      @sitting.debates.sections[9].contributions.last.text.should == text
    end
  
    it 'should create OrdersOfTheDay for section titled Orders of the Day' do
      @orders_of_the_day.should be_an_instance_of(Section)
    end
  
    it 'should set OrdersOfTheDay title to Orders of the Day' do
      @orders_of_the_day.title.should == 'Orders of the Day'
    end
  
    it 'should create first Orders of the Day section' do
      @orders_of_the_day.sections[0].should be_an_instance_of(Section)
    end
  
    it 'should set title on Orders of the Day section' do
      @orders_of_the_day.sections[0].title.should == 'Education (Amendment) Bill'
    end
  
    it 'should set first contribution on Order of the Day section' do
      @orders_of_the_day.sections[0].contributions[0].should be_an_instance_of(ProceduralContribution)
      @orders_of_the_day.sections[0].contributions[0].text.should == '<i>Considered in Committee.</i>'
      @orders_of_the_day.sections[0].contributions[0].xml_id.should == 'S6CV0089P0-00791'
    end
  
    it 'should create division placeholder in contributions for division element' do
      @division_placeholder.should be_an_instance_of(DivisionPlaceholder)
    end
  
    it 'should create division name' do
      @division.name.should == 'Division No. 29]'
    end
  
    it 'should create division time text' do
      @division.time_text.should == '[11.15 pm>'
    end
  
    it 'should set division placeholder text to be contents of division element' do
      @division_placeholder.text.should == %Q|<table>\n<tr>\n<td><b>Division No. 29]</b></td>\n<td align=\"right\"><b>[11.15 pm></b></td>\n</tr>\n<tr>\n<td align=\"center\" colspan=\"2\"><b>AYES</b></td>\n</tr>\n<tr>\n<td>Alexander, Richard</td>\n<td>Ancram, Michael</td>\n</tr>\n<tr>\n<td>Amess, David</td>\n<td>Aspinwall, Jack</td>\n</tr>\n</table>\n<col>124</col>\n<table>\n<tr>\n<td>Atkinson, David <i>(B m'th E)</i></td>\n<td>Howarth, Alan <i>(Stratf'd-on-A)</i></td>\n</tr>\n<tr>\n<td>Baker, Nicholas <i>(Dorset N)</i></td>\n<td>Howarth, Gerald <i>(Cannock)</i></td>\n</tr>\n<tr>\n<td>&#x00D6;pik, Lembit</td>\n<td>Hubbard-Miles, Peter</td>\n</tr>\n<tr>\n<td>Beaumont-Dark, Anthony</td>\n<td>Hunt, David <i>(Wirral)</i></td>\n</tr>\n<tr>\n<td>Bellingham, Henry</td>\n<td>Hunter, Andrew</td>\n</tr>\n<tr>\n<td>Benyon, William</td>\n<td>Hurd, Rt Hon Douglas</td>\n</tr>\n<tr>\n<td>Blackburn, John</td>\n<td>Jackson, Robert</td>\n</tr>\n<tr>\n<td>Body, Richard</td>\n<td>Jessel, Toby</td>\n</tr>\n<tr>\n<td>Boscawen, Hon Robert</td>\n<td>Jones, Gwilym <i>(Cardiff N)</i></td>\n</tr>\n<tr>\n<td>Bottomley, Peter</td>\n<td>Jones, Robert <i>(Herts W)</i></td>\n</tr>\n<tr>\n<td>Bottomley, Mrs Virginia</td>\n<td>Kellett-Bowman, Mrs Elaine</td>\n</tr>\n<tr>\n<td>Bowden, A. <i>(Brighton K'to'n)</i></td>\n<td>Knight, Greg <i>(Derby N)</i></td>\n</tr>\n<tr>\n<td>Bowden, Gerald <i>(Dulwich)</i></td>\n<td>Knight, Dame Jill <i>(Edgbaston)</i></td>\n</tr>\n<tr>\n<td>Brandon-Bravo, Martin</td>\n<td>Knowles, Michael</td>\n</tr>\n<tr>\n<td>Bright, Graham</td>\n<td>Lang, Ian</td>\n</tr>\n<tr>\n<td>Brinton, Tim</td>\n<td>Latham, Michael</td>\n</tr>\n<tr>\n<td>Brooke, Hon Peter</td>\n<td>Lawler, Geoffrey</td>\n</tr>\n<tr>\n<td>Brown, M. <i>(Brigg &amp; Cl'thpes)</i></td>\n<td>Lennox-Boyd, Hon Mark</td>\n</tr>\n<tr>\n<td>Bruinvels, Peter</td>\n<td>Lester, Jim</td>\n</tr>\n<tr>\n<td>Burt, Alistair</td>\n<td>Lord, Michael</td>\n</tr>\n<tr>\n<td>Butterfill, John</td>\n<td>McCurley, Mrs Anna</td>\n</tr>\n<tr>\n<td>Carlisle, Kenneth <i>(Lincoln)</i></td>\n<td>MacKay, John <i>(Argyll &amp; Bute)</i></td>\n</tr>\n<tr>\n<td>Carttiss, Michael</td>\n<td>Maclean, David John</td>\n</tr>\n<tr>\n<td>Cash, William</td>\n<td>McNair-Wilson, M. <i>(N'bury)</i></td>\n</tr>\n<tr>\n<td>Chapman, Sydney</td>\n<td>McQuarrie, Albert</td>\n</tr>\n<tr>\n<td>Chope, Christopher</td>\n<td>Major, John</td>\n</tr>\n<tr>\n<td>Clark, Dr Michael <i>(Rochford)</i></td>\n<td>Malins, Humfrey</td>\n</tr>\n<tr>\n<td>Conway, Derek</td>\n<td>Malone, Gerald</td>\n</tr>\n<tr>\n<td>Coombs, Simon</td>\n<td>Marlow, Antony</td>\n</tr>\n<tr>\n<td>Cope, John</td>\n<td>Mather, Carol</td>\n</tr>\n<tr>\n<td>Corrie, John</td>\n<td>Maxwell-Hyslop, Robin</td>\n</tr>\n<tr>\n<td>Cranborne, Viscount</td>\n<td>Mayhew, Sir Patrick</td>\n</tr>\n<tr>\n<td>Crouch, David</td>\n<td>Merchant, Piers</td>\n</tr>\n<tr>\n<td>Currie, Mrs Edwina</td>\n<td>Miller, Hal <i>(B'grove)</i></td>\n</tr>\n<tr>\n<td>Dicks, Terry</td>\n<td>Mills, Iain <i>(Meriden)</i></td>\n</tr>\n<tr>\n<td>Dorrell, Stephen</td>\n<td>Mitchell, David <i>(Hants NW)</i></td>\n</tr>\n<tr>\n<td>Douglas-Hamilton, Lord J.</td>\n<td>Moate, Roger</td>\n</tr>\n<tr>\n<td>Durant, Tony</td>\n<td>Moynihan, Hon C.</td>\n</tr>\n<tr>\n<td>Dykes, Hugh</td>\n<td>Murphy, Christopher</td>\n</tr>\n<tr>\n<td>Evennett, David</td>\n<td>Neubert, Michael</td>\n</tr>\n<tr>\n<td>Eyre, Sir Reginald</td>\n<td>Newton, Tony</td>\n</tr>\n<tr>\n<td>Fallon, Michael</td>\n<td>Nicholls, Patrick</td>\n</tr>\n<tr>\n<td>Favell, Anthony</td>\n<td>Normanton, Tom</td>\n</tr>\n<tr>\n<td>Fenner, Mrs Peggy</td>\n<td>Norris, Steven</td>\n</tr>\n<tr>\n<td>Forsyth, Michael <i>(Stirling)</i></td>\n<td>Oppenheim, Phillip</td>\n</tr>\n<tr>\n<td>Forth, Eric</td>\n<td>Ottaway, Richard</td>\n</tr>\n<tr>\n<td>Freeman, Roger</td>\n<td>Page, Sir John <i>(Harrow W)</i></td>\n</tr>\n<tr>\n<td>Gale, Roger</td>\n<td>Page, Richard <i>(Herts SW)</i></td>\n</tr>\n<tr>\n<td>Galley, Roy</td>\n<td>Patten, Christopher <i>(Bath)</i></td>\n</tr>\n<tr>\n<td>Garel-Jones, Tristan</td>\n<td>Portillo, Michael</td>\n</tr>\n<tr>\n<td>Goodhart, Sir Philip</td>\n<td>Powley, John</td>\n</tr>\n<tr>\n<td>Gow, Ian</td>\n<td>Proctor, K. Harvey</td>\n</tr>\n<tr>\n<td>Gower, Sir Raymond</td>\n<td>Raffan, Keith</td>\n</tr>\n<tr>\n<td>Greenway, Harry</td>\n<td>Rhodes James, Robert</td>\n</tr>\n<tr>\n<td>Gregory, Conal</td>\n<td>Ridley, Rt Hon Nicholas</td>\n</tr>\n<tr>\n<td>Griffiths, Sir Eldon</td>\n<td>Roe, Mrs Marion</td>\n</tr>\n<tr>\n<td>Griffiths, Peter <i>(Portsm'th N)</i></td>\n<td>Sainsbury, Hon Timothy</td>\n</tr>\n<tr>\n<td>Ground, Patrick</td>\n<td>Shepherd, Colin <i>(Hereford)</i></td>\n</tr>\n<tr>\n<td>Hamilton, Hon A. <i>(Epsom)</i></td>\n<td>Spencer, Derek</td>\n</tr>\n<tr>\n<td>Hamilton, Neil <i>(Tatton)</i></td>\n<td>Squire, Robin</td>\n</tr>\n<tr>\n<td>Hanley, Jeremy</td>\n<td>Stanbrook, Ivor</td>\n</tr>\n<tr>\n<td>Harris, David</td>\n<td>Thompson, Donald <i>(Calder V)</i></td>\n</tr>\n<tr>\n<td>Harvey, Robert</td>\n<td>Thompson, Patrick <i>(N'ich N)</i></td>\n</tr>\n<tr>\n<td>Hayward, Robert</td>\n<td>Thurnham, Peter</td>\n</tr>\n<tr>\n<td>Heathcoat-Amory, David</td>\n<td>Wakeham, Rt Hon John</td>\n</tr>\n<tr>\n<td>Heddle, John</td>\n<td>Waller, Gary</td>\n</tr>\n<tr>\n<td>Hickmet, Richard</td>\n<td>Warren, Kenneth</td>\n</tr>\n<tr>\n<td>Hind, Kenneth</td>\n<td>Wells, Bowen <i>(Hertford)</i></td>\n</tr>\n<tr>\n<td>Hirst, Michael</td>\n<td></td>\n</tr>\n<tr>\n<td>Hogg, Hon Douglas <i>(Gr'th'm)</i></td>\n<td>Tellers for the Ayes:</td>\n</tr>\n<tr>\n<td>Holland, Sir Philip <i>(Gedling)</i></td>\n<td>Mr. Peter Lloyd and</td>\n</tr>\n<tr>\n<td>Holt, Richard</td>\n<td>Mr. Francis Maude.</td>\n</tr>\n<tr>\n<td>Howard, Michael</td>\n<td></td>\n</tr>\n</table>\n<table>\n<tr>\n<td align=\"center\" colspan=\"2\"><b>NOES</b></td>\n</tr>\n<tr>\n<td>Alton, David</td>\n<td>Brown, Gordon <i>(D'f'mline E)</i></td>\n</tr>\n<tr>\n<td>Atkinson, N. <i>(Tottenham)</i></td>\n<td>Bruce, Malcolm</td>\n</tr>\n<tr>\n<td>Bennett, A. <i>(Dent'n &amp; Red'sh)</i></td>\n<td>Caborn, Richard</td>\n</tr>\n<tr>\n<td>Bermingham, Gerald</td>\n<td>Callaghan, Jim <i>(Heyw'd &amp; M)</i></td>\n</tr>\n<tr>\n<td>Boyes, Roland</td>\n<td>Campbell-Savours, Dale</td>\n</tr>\n</table>\n<image src=\"S6CV0089P0I0072\"></image>\n<col>125</col>\n<table>\n<tr>\n<td>Clarke, Thomas</td>\n<td>Kennedy, Charles</td>\n</tr>\n<tr>\n<td>Clelland, David Gordon</td>\n<td>Lamond, James</td>\n</tr>\n<tr>\n<td>Clwyd, Mrs Ann</td>\n<td>Leighton, Ronald</td>\n</tr>\n<tr>\n<td>Cocks, Rt Hon M. <i>(Bristol S.)</i></td>\n<td>Lloyd, Tony <i>(Stretford)</i></td>\n</tr>\n<tr>\n<td>Cook, Robin F. <i>(Livingston)</i></td>\n<td>McDonald, Dr Oonagh</td>\n</tr>\n<tr>\n<td>Corbyn, Jeremy</td>\n<td>McKay, Allen <i>(Penistone)</i></td>\n</tr>\n<tr>\n<td>Cunliffe, Lawrence</td>\n<td>McWilliam, John</td>\n</tr>\n<tr>\n<td>Dalyell, Tam</td>\n<td>Madden, Max</td>\n</tr>\n<tr>\n<td>Davies, Ronald <i>(Caerphilly)</i></td>\n<td>Marek, Dr John</td>\n</tr>\n<tr>\n<td>Deakins, Eric</td>\n<td>Maxton, John</td>\n</tr>\n<tr>\n<td>Dixon, Donald</td>\n<td>Millan, Rt Hon Bruce</td>\n</tr>\n<tr>\n<td>Dormand, Jack</td>\n<td>Miller, Dr M. S. <i>(E Kilbride)</i></td>\n</tr>\n<tr>\n<td>Douglas, Dick</td>\n<td>Morris, Rt Hon A. <i>(W'shawe)</i></td>\n</tr>\n<tr>\n<td>Eadie, Alex</td>\n<td>Patchett, Terry</td>\n</tr>\n<tr>\n<td>Eastham, Ken</td>\n<td>Pike, Peter</td>\n</tr>\n<tr>\n<td>Evans, John <i>(St. Helens N)</i></td>\n<td>Powell, Raymond <i>(Ogmore)</i></td>\n</tr>\n<tr>\n<td>Ewing, Harry</td>\n<td>Radice, Giles</td>\n</tr>\n<tr>\n<td>Fields, T. <i>(L'pool Broad Gn)</i></td>\n<td>Rogers, Allan</td>\n</tr>\n<tr>\n<td>Fisher, Mark</td>\n<td>Short, Ms Clare <i>(Ladywood)</i></td>\n</tr>\n<tr>\n<td>Foster, Derek</td>\n<td>Skinner, Dennis</td>\n</tr>\n<tr>\n<td>Foulkes, George</td>\n<td>Snape, Peter</td>\n</tr>\n<tr>\n<td>Freud, Clement</td>\n<td>Spearing, Nigel</td>\n</tr>\n<tr>\n<td>Godman, Dr Norman</td>\n<td>Steel, Rt Hon David</td>\n</tr>\n<tr>\n<td>Golding, John</td>\n<td>Strang, Gavin</td>\n</tr>\n<tr>\n<td>Hamilton, James <i>(M'well N)</i></td>\n<td>Thomas, Dr R. <i>(Carmarthen)</i></td>\n</tr>\n<tr>\n<td>Hardy, Peter</td>\n<td>Wardell, Gareth <i>(Gower)</i></td>\n</tr>\n<tr>\n<td>Haynes, Frank</td>\n<td></td>\n</tr>\n<tr>\n<td>Hogg, N. <i>(C'nauld &amp; Kilsyth)</i></td>\n<td>Tellers for the Noes:</td>\n</tr>\n<tr>\n<td>Home Robertson, John</td>\n<td>Mr. Alex Carlile and</td>\n</tr>\n<tr>\n<td>Howells, Geraint</td>\n<td>Mr. James Wallace.</td>\n</tr>\n<tr>\n<td>Hughes, Sean <i>(Knowsley S)</i></td>\n<td></td>\n</tr>\n</table>|
    end
  
    it 'should create aye vote' do
      @division.votes[0].should_not be_nil
      @division.votes[0].should be_an_instance_of(AyeVote)
    end
  
    it 'should set aye vote name' do
      @division.votes[0].name.should == 'Alexander, Richard'
    end
  
    it 'should set aye vote column' do
      @division.votes[0].column.should == '123'
    end
  
    it 'should set aye vote name and constituency when present' do
      @division.votes[4].name.should == 'Atkinson, David'
      @division.votes[4].constituency.should == "B m'th E"
    end
  
    it 'should correctly parse vote names that include HTML entities' do
      @division.votes[8].name.should == '&#x00D6;pik, Lembit'
    end
  
    it 'should create teller aye votes for the cells that appear after the heading "Tellers for the Ayes" in the right hand column of the division table' do
      @division.aye_teller_votes.size.should == 2
      @division.aye_teller_votes[0].name.should == 'Mr. Peter Lloyd'
      @division.aye_teller_votes[1].name.should == 'Mr. Francis Maude.'
    end
  
    it 'should create aye votes for the cells that appear after the heading "Tellers for the Ayes" in the left hand column of the division table' do
      [@division.votes[142], @division.votes[144], @division.votes[146]].each do |division|
        division.should_not be_nil
        division.should be_an_instance_of(AyeVote)
      end
    end
  
    it 'should create noe vote' do
      @division.votes[147].should_not be_nil
      @division.votes[147].should be_an_instance_of(NoeVote)
    end
  
    it 'should create noe vote name' do
      @division.votes[147].name.should == 'Alton, David'
    end
  
    it 'should create teller noe votes for the cells that appear after the heading "Tellers for the Noes" in the right hand column of the division table' do
      [@division.votes[212], @division.votes[214]].each do |division|
        division.should_not be_nil
        division.should be_an_instance_of(NoeTellerVote)
      end
    end
  
    it 'should create noe votes for the cells that appear after the heading "Tellers for the Noes" in the left hand column of the division table' do
      [@division.votes[211], @division.votes[213], @division.votes[215]].each do |division|
        division.should_not be_nil
        division.should be_an_instance_of(NoeVote)
      end
    end
  
    it 'should set division time when time format is [6.4 pm' do
      division = @sitting.debates.sections[10].contributions.select {|c| c.is_a? DivisionPlaceholder}[0].division
      division.name.should == 'Division No. 27]'
      division.time_text.should == '[6.4 pm'
    end
  
    it "should extract column tags within procedural contributions" do
      @last_procedural_contribution.column_range.should == '744,745'
    end
  
    it_should_behave_like "All sittings"
  end
  
  describe 'when parsing multiple times' do 
    
    def get_anchor_ids
      volume = mock_model(Volume)
      source_file = mock_model(SourceFile, :name => "S6CV0417P1", :volume => volume)
      data_file = mock_model(DataFile, :source_file => source_file, 
                                       :name => 'housecommons_2004_02_12.xml')
      sitting = parse_hansard_file(Hansard::CommonsParser, data_file_path('housecommons_multiple_nested_sections_in_oralquestions.xml'), data_file, source_file)
      sitting.contributions.map{ |contribution| contribution.anchor_id }
     end
     
     it 'should set the same anchor id on contributions as on previous parses' do 
       first_anchor_ids = get_anchor_ids
       second_anchor_ids = get_anchor_ids
       first_anchor_ids.should == second_anchor_ids
     end 
   
   end
   
end
