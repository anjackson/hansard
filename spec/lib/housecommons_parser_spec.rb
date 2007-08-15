require File.dirname(__FILE__) + '/hansard_parser_spec_helper'

describe Hansard::HouseCommonsParser, "when passed housecommons_1985_12_16.xml" do
  before(:all) do
    @sitting_type = HouseOfCommonsSitting
    @sitting_date = Date.new(1985,12,16)
    @sitting_date_text = 'Monday 16 December 1985'
    @sitting_title = 'House of Commons' 
    @sitting_column = '1'
    @sitting_text = %Q[<p id="S6CV0089P0-00360" align="center"><i>The House met at half-past Two o'clock</i></p>]

    @sitting = parse_hansard 's6cv0089p0/housecommons_1985_12_16.xml'
    @sitting.save!

    @first_section = @sitting.debates.sections.first

    @oral_questions = @sitting.debates.oral_questions
    @first_questions_section = @sitting.debates.oral_questions.sections.first
    @first_question = @sitting.debates.oral_questions.sections.first.questions.first
    @first_question_contribution = @first_question.contributions.first
    @second_question_contribution = @first_question.contributions[1]

    @third_section = @sitting.debates.sections[2]
    @third_section_first_contribution = @third_section.contributions.first
    @third_section_second_contribution = @third_section.contributions[1]

    @seventh_section = @sitting.debates.sections[6]
    @seventh_section_first_contribution = @seventh_section.contributions.first
    @seventh_section_second_contribution = @seventh_section.contributions[1]
    
    @eighth_section = @sitting.debates.sections[7]
    @eighth_section_first_contribution = @eighth_section.contributions.first
    @eighth_section_second_contribution = @eighth_section.contributions[1]
  end

  after(:all) do
    Sitting.delete_all
    Section.delete_all
    Contribution.delete_all
  end


  it 'should create first section in debates' do
    @first_section.should_not be_nil
    @first_section.should be_an_instance_of(ProceduralSection)
  end

  it 'should set text on first section in debates' do
    @first_section.contributions[0].text.should == '[MR. SPEAKER <i>in the Chair</i>]'
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
    @first_question_contribution.should be_an_instance_of(OralQuestionContribution)
  end

  it 'should set parent section on first oral question contribution' do
    @first_question_contribution.section_id.should == @first_question.id
    @first_question_contribution.section.should == @first_question
  end

  it 'should set xml_id on first oral question contribution' do
    @first_question_contribution.xml_id.should == 'S6CV0089P0-00362'
  end

  it 'should set oral question number on first oral question contribution' do
    @first_question_contribution.oral_question_no.should == '1.'
  end

  it 'should set member on first oral question contribution' do
    @first_question_contribution.member.should == 'Mr. Douglas'
  end

  it 'should set member contribution on first oral question contribution' do
    @first_question_contribution.member_contribution.should == ' asked the Secretary of State for Energy if he will make a statement on visits by Ministers in his Department to pits in the Scottish coalfield.'
  end

  it 'should set column range on first oral question contribution' do
    @first_question_contribution.column_range.should == '1'
  end


  it 'should set second oral question contribution' do
    @second_question_contribution.should_not be_nil
    @second_question_contribution.should be_an_instance_of(OralQuestionContribution)
  end

  it 'should set parent section on second oral question contribution' do
    @second_question_contribution.section_id.should == @first_question.id
    @second_question_contribution.section.should == @first_question
  end

  it 'should set xml_id on second oral question contribution' do
    @second_question_contribution.xml_id.should == 'S6CV0089P0-00363'
  end

  it 'should not set oral question number on second oral question contribution' do
    @second_question_contribution.oral_question_no.should be_nil
  end

  it 'should set member on second oral question contribution' do
    @second_question_contribution.member.should == 'The Parliamentary Under-Secretary of State for Energy (Mr. David Hunt)'
  end

  it 'should set member contribution on second oral question contribution' do
    @second_question_contribution.member_contribution.should == ': I was extremely impressed during my recent visit to the Scottish coalfield to hear of the measures being taken to reduce costs and improve productivity.'
  end

  it 'should set column range on second oral question contribution' do
    @second_question_contribution.column_range.should == '1'
  end


  it 'should create third section in debates' do
    @third_section.should_not be_nil
    @third_section.should be_an_instance_of(DebatesSection)
  end

  it 'should set time text on third section in debates' do
    @third_section.time_text.should == '3.30 pm'
  end

  it 'should set time on third section in debates' do
    @third_section.time.strftime('%H:%M:%S').should == '15:30:00'
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


  it 'should set first (procedural) contribution on third section' do
    @third_section_first_contribution.should_not be_nil
    @third_section_first_contribution.should be_an_instance_of(ProceduralContribution)
  end

  it 'should set first (procedural) contribution text on third section' do
    @third_section_first_contribution.text.should == '3.30 pm'
  end

  it 'should set first (procedural) contribution xml id on third section' do
    @third_section_first_contribution.xml_id.should == 'S6CV0089P0-00525'
  end

  it 'should set first (procedural) contribution column range on third section' do
    @third_section_first_contribution.column_range.should == '21'
  end
  
  it 'should set first (procedural) contribution parent on third section' do
    @third_section_first_contribution.section_id.should == @third_section.id 
    @third_section_first_contribution.section.should == @third_section 
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
    @third_section_second_contribution.member.should == 'The Secretary of State for Social Services (Mr. Norman Fowler)'
  end

  it 'should set second (member) contribution text on third section' do
    @third_section_second_contribution.text.should == %Q[: With permission, Mr. Speaker, I shall make a statement on the Social Security White Paper which I am publishing today.<lb></lb>\nIn June the Government published a Green Paper which set out in detail the case for change, the Government's objectives for social security and our proposals for achieving them. That Green Paper marked a further stage in the process of review and public consultation which began two years ago in the autumn of 1983.<lb></lb>\nThe Government have four main aims. We want to see a simpler system of social security which provides a better service to the public. By common consent, social security at present is too complex. There are some 30 benefits, each with separate and frequently conflicting rules of entitlement, and supplementary benefit alone requires almost 40,000 staff to administer it.<lb></lb>\nWe want to see more people looking forward to greater independence in retirement. Only half the work force currently have occupational pensions of their own. Our plans extend not only to occupational pensions but, for the first time, provide a new right to personal pensions.<lb></lb>\nWe want a system which is financially secure. As the Government Actuary's report, published with the White Paper, demonstrates, the future cost of the state earnings-related pension scheme will grow substantially&#x2014;at the same time as the ratio of contributors to pensioners worsens. The Government believe that this problem must be tackled now.<lb></lb>\nAbove all, we want to see more effective help going to those who most need it. More than half of those living on the lowest incomes today are in families with children. This includes both families where the parents are unemployed and low-income working families. Added to this people can still find themselves with less income in work than if they were unemployed. Others can find that a pay rise in work can actually make them worse off. The Government believe that urgent action is necessary to tackle these problems.<lb></lb>\nOne of the major priorities of the Government's proposals is to make better provision for low-income working families with children. Accordingly, we propose to abolish the present family income supplement and to introduce a new benefit, family credit.<lb></lb>\nFamily credit is designed to ensure that families with children will be better off in work. It will be based on take-home or net pay&#x2014;rather than gross earnings, as with family income supplement&#x2014;so that the worst effects of the poverty trap are eliminated.<lb></lb>\nWe expect that, compared with family income supplement, family credit will give help to an extra 200,000 families. In other words, twice as many low income families with children will benefit from the new scheme. Family credit will be paid through the pay packet, but it should be emphasised that child benefit will be paid in addition and that that payment will go, as now, direct to the mothers.<lb></lb>\nWe also intend to bring extra support to families who are not in work. This will be achieved through the new income support scheme. A family premium&#x2014;a special higher level of benefit&#x2014;will be paid on top of the basic\n<col>22</col>\nincome support rate and on top of the rates for individual children. One of the groups who will most gain from this change will be unemployed families with children.<lb></lb>\nThe income support scheme will replace supplementary benefit. The regular extra payments now made on the basis of detailed individual assessment will be absorbed into the main rates of benefit. As well as a premium for families with children, there will be an additional premium for lone parents and premiums for pensioners and the long-term sick and disabled. At the same time, the capital rule, which at present is an inflexible &#x00A3;3,000 cut off, will be substantiall eased, and we will also ease the earnings rules for lone parents, disabled people and long-term unemployed families.<lb></lb>\nWhile the broad pattern of income support will remain as set out in the Green Paper, we have modified our proposals in the light of consultations in two significant ways.<lb></lb>\nFirst, the income support rate will still be based on age divisions at 18 and 25 for single people. However, in order to help young families with children in particular, we now intend to have the same rate for all couples over 18.<lb></lb>\nSecondly, we intend to increase the help for families with more than one disabled child. The Green Paper proposed a double family premium where there was one disabled child or more. We have now decided to pay the extra premium for each disabled child in a household.<lb></lb>\nThis last change will reinforce the special attention which we give to disabled people in our proposals. They will benefit from the premium in income support and from a higher earnings disregard. Overall, disabled people on low incomes will benefit significantly from the proposals.<lb></lb>\nHowever well designed the income support scheme may be, it cannot anticipate every special or emergency need. These needs will be dealt with by the social fund.<lb></lb>\nInstead of the present small universal maternity and death grants&#x2014;which have both remained at the same value for over 15 years&#x2014;proper help will be available from the fund to all low income families, not just those on supplementary benefit. The grant for funeral expenses will ensure that the full cost of the funeral can be met, and it is planned that the maternity grant should be set at about &#x00A3;75. Grants will also be given for community care purposes; for example, to help someone leaving a long-stay hospital. In addition, the fund will provide loans to help claimants cope with items other than normal weekly needs.<lb></lb>\nThe main structure of our housing benefit proposals has been acknowledged as an important simplification of the scheme. Treating employed and unemployed people alike, and so getting rid of two separate systems in housing benefit, has been particularly welcomed.<lb></lb>\nWe shall go ahead with this, but I intend, in response to consultations, to make two significant changes to the Green Paper proposals. First, I recognise the anxieties expressed about the effect of a single taper for rent and rates on owner-occupiers, particularly pensioners. I also recognise the concern of local authorities that a single taper would create administrative difficulties for them. We shall therefore keep separate tapers for rent and rates, and this will still be a substantial simplification compared with the six tapers in the present system.<lb></lb>\nSecondly, although the general power to run local housing benefit schemes will be ended, local authorities will retain their power to grant extra benefit to individual\n<image src=\"S6CV0089P0I0021\"></image>\n<col>23</col>\nclaimants in exceptional circumstances. I have also decided that they should retain their power to give special treatment to war pensioners.<lb></lb>\nAs we made clear in the Green Paper, we believe that the basis on which help is provided with rates needs to be changed. At present, around 7 million householders receive help with some or all of their rates bill, and up to 3 million householders pay no rates. We stand by the principle that everyone should make a contribution towards the cost of his local services. The White Paper therefore reaffirms the proposal that everyone should pay at least 20 per cent. of his rates, but the proposals which my right hon. Friend the Secretary of State for the Environment will be bringing forward shortly on the reform of local taxation may affect the way this contribution is made.<lb></lb>\nThe Government will be carrying forward the proposals for directing widows' benefits to those who need them most and for making maternity allowance more flexible and more closely related to recent work. The new lump sum payment of &#x00A3;1,000 to widows will be tax-free and will be ignored when considering help with funeral expenses. The White Paper also proposes that maternity allowances, like statutory sick pay, should be paid through employers, and a consultation document will be published shortly on this.<lb></lb>\nOn timing, we shall move to the first April uprating in 1987 and at that time we shall introduce other changes like statutory maternity allowance and the new system of help with maternity and funeral costs. The main structural changes to income-related benefits and the other elements of the social fund will be introduced in April 1988. This recognises the arguments of employers and local authorities that the timetable must allow them to make proper preparations.<lb></lb>\nAs far as income-related benefits are concerned, a technical annex is published with the White Paper. The figures show the possible distributional effects of the changes, but these can be no more than illustrative. The actual position at the time of change will depend, among other things, on the exact benefit rates decided for April 1988, and the illustrative figures take no account of any changes resulting from the reform of rates.<lb></lb>\nAs far as pensions policy is concerned, the Government Actuary's report, published with the White Paper, shows that if no action is taken, total pension costs will increase from under &#x00A3;15&#x00B7;5 billion to nearly &#x00A3;49 billion a year provided that the basic pension is uprated by prices. If, as some urge, the basic pension is uprated in line with earnings, the total pension cost increases to nearly &#x00A3;73 billion, which would require a national insurance contribution of 27&#x00B7;5 per cent. The cost of SERPS alone will increase from barely &#x00A3;200 million today to &#x00A3;25&#x00B7;5 billion.<lb></lb>\nThe Government cannot ignore the vast pension bill which is being handed down to our children. In the consultation a number of important organisations recognised that case but argued that, rather than completely replacing SERPS, the costs could be reduced by modifying its provisions. In testing whether a policy of modifying SERPS would be acceptable, the Government have two major objectives. First, we want to see the future cost of SERPS substantially reduced. Secondly, and even more fundamentally, we want to see many more people\n<col>24</col>\nwith their own pension. It is on the basis that both of those objectives can be achieved that the Government are prepared to change the proposals from those put forward in the Green Paper.<lb></lb>\nThe Government propose to modify the scheme so that costs in the next century can be afforded. As with the Green Paper proposals, the Government recognise the particular needs of those nearest retirement. The SERPS changes will not affect anyone retiring this century, nor anyone widowed this century. There will also be a transitional period as the new scheme comes into effect fully in 2010. The basic pension is entirely unaffected by the proposals, and we will continue fully to protect its value.<lb></lb>\nThe changes to SERPS are that occupational schemes contracted out of the state scheme should be responsible for inflation-proofing guaranteed minimum pensions in payment up to 3 per cent. a year; SERPS pensions should be based on a lifetime's earnings, not on the best 20 years as now, but special protection will be built in for women who have breaks in work to bring up families and for those who become disabled and people looking after them; SERPS pensions should be calculated on 20 per cent. of earnings rather than 25 per cent.; and widows and widowers over 65 should be allowed to inherit half their spouse's SERPS rights, rather than the full amount as now.<lb></lb>\nHowever, policy on SERPS is only part of the Government's pensions strategy. Our central aim is to provide many more people with their own pension. The White Paper puts forward a six point plan to achieve that. First, a special incentive will be given to encourage the setting up a new occupational pension schemes. That will consist of a reduction, or rebate, on national insurance contributions. An extra 2 per cent. rebate will be added to the existing rebate, making a total incentive of almost 8 per cent. That special rebate will last for five years.<lb></lb>\nSecondly, for the first time, every employee will be able to take a personal pension, whether or not his employer runs an occupational scheme. The holder of a personal pension will also receive the special national insurance incentive and his contributions will qualify for tax relief.<lb></lb>\nThirdly, for the first time, employers will be able to contract out of the state scheme by guaranteeing a level of contribution to an occupational scheme&#x2014;rather than accept the unlimited liability of promising a \"final salary\" pension. Those new arrangements will also open the way for more industry-wide schemes.<lb></lb>\nFourthly, building societies, banks and unit trusts will be able to provide personal pension savings schemes, as well as group schemes.<lb></lb>\nFifthly, all members of occupational pension schemes will in future have the right to pay additional voluntary contributions in order to boost their income in retirement.<lb></lb>\nSixthly, people with personal pensions will be fully covered by the new investor protection arrangements to be made for all financial services.<lb></lb>\nThe changes build on top of the reforms introduced by the Social Security Act 1985 which protect the rights of early leavers. The White Paper proposes that that protection will be extended to all members of schemes leaving after two years rather than five years, as now. Anyone changing jobs will be able to transfer all his rights into a personal pension.<lb></lb>\nThe effect of the White Paper proposals will be to direct substantially more help to low income families with\n<image src=\"S6CV0089P0I0022\"></image>\n<col>25</col>\nchildren, and to provide more help for disabled people on low incomes. We will take new steps to increase the spread of occupational pensions and give everyone the right to have a personal pension. We will provide a simpler and more effective benefit structure, and have now embarked on the biggest computer project of its kind in Western Europe.<lb></lb>\nFollowing the White Paper, the Government will introduce comprehensive legislation early in the new year. The aim will be to achieve a modern social security system directing help where that help is needed.]
  end

  it 'should set second (member) contribution parent on third section' do
    @third_section_second_contribution.section_id.should == @third_section.id 
    @third_section_second_contribution.section.should == @third_section 
  end


  it 'should create procedural contribution for time stamp paragraphs containing middle dot (&#x00B7;)' do
    @seventh_section_first_contribution.should be_an_instance_of(ProceduralContribution)
  end

  it 'should add member constituency to contribution if constituency is present' do
    @seventh_section_second_contribution.member_constituency.should == '(Workington)'
  end
  
  it 'should create list of columns in column range when contribution text contains col element' do
    @seventh_section_second_contribution.column_range.should == '47,48'
  end


  it 'should create eighth section in debates' do
    @eighth_section.should_not be_nil
    @eighth_section.should be_an_instance_of(ProceduralSection)
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

  it_should_behave_like "All sittings"
  it_should_behave_like "All commons sittings"
end
