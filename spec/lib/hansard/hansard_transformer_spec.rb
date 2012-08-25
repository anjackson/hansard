require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/../../../lib/hansard/hansard_transformer'

describe Hansard::Transformer do

  before(:each) do
    @result_directory = 'result'
    @transformer = Hansard::Transformer.new('source',@result_directory)
    @transformer.stub!(:write_result)
  end

  def xml text
    text.squeeze!(' ')
    text.gsub!("\n ", "\n")
    text.gsub!("\r", '')
    text
  end

  def tranform_xml text
    tranform_this_xml xml(text)
  end

  def tranform_this_xml xml
    @transformer.stub!(:open_source).and_return '<HansardDoc><House name="Commons">'+xml+'</House></HansardDoc>'
    @transformed = @transformer.transform
    @transformed
  end

  def assert_correct text, ignore_tags=[]
    ignore_tags << 'housecommons'
    expected = xml(text).gsub("\n",'')
    result = @transformed.gsub("\n",'')

    ignore_tags.each do |tag|
      result.gsub!("<#{tag}>",'')
      result.gsub!("</#{tag}>",'')
    end
    result.should == expected
  end

  it 'should create date element correctly' do
    tranform_xml(%Q|<hs_6fDate UID="a_uid" url="a_url">
            <I>Monday 18 February 2008</I>
          </hs_6fDate>|)
    assert_correct("<date format='2008-02-18'>Monday 18 February 2008</date>")
  end

  it 'should create date element correctly' do
    tranform_this_xml('<hs_6fDate><I>Monday 4
February 2008</I></hs_6fDate>')
    @transformed.should == "<housecommons>
<date format='2008-02-04'>Monday 4
February 2008</date></housecommons>"
  end

  it 'should put title element inside debates element if there is no debates element' do
    tranform_xml(%Q|<hs_3OralAnswers UID="a_uid" url="a_url">Oral Answers to Questions</hs_3OralAnswers>|)
    assert_correct("<debates><title>Oral Answers to Questions</title></debates>", ignore=['section','oralquestions'])
  end

  it 'should put all title elements inside debates element if there is no debates element' do
    tranform_xml(%Q|<hs_3OralAnswers UID="a_uid" url="a_url">Oral Answers to Questions</hs_3OralAnswers>
      <hs_6bDepartment UID="a_uid_2" url="a_url_2">
        <DepartmentName xid="29">Work and Pensions</DepartmentName>
      </hs_6bDepartment>|)
    assert_correct('<debates><title>Oral Answers to Questions</title><title>Work and Pensions</title></debates>', ignore=['section','oralquestions'])
  end

  it 'should put title element inside section element' do
    tranform_xml(%Q|<hs_3OralAnswers UID="a_uid" url="a_url">Oral Answers to Questions</hs_3OralAnswers>|)
    assert_correct('<section><title>Oral Answers to Questions</title></section>', ignore=['debates','oralquestions'])
  end

  it 'should put each title element inside a section element' do
    tranform_xml(%Q|<hs_3OralAnswers UID="a_uid" url="a_url">Oral Answers to Questions</hs_3OralAnswers>
      <hs_6bDepartment UID="a_uid_2" url="a_url_2">
        <DepartmentName xid="29">Work and Pensions</DepartmentName>
      </hs_6bDepartment>|)
    assert_correct('<section><title>Oral Answers to Questions</title></section><section><title>Work and Pensions</title></section>', ignore=['debates','oralquestions'])
  end

  it 'should not put title element inside debates element if title text is "Prayers"' do
    tranform_xml(%Q|<hs_6bBigBoldHdg UID="a_uid" url="a_url">Prayers</hs_6bBigBoldHdg>|)
    assert_correct('<title>Prayers</title>')
  end

  it 'should not put title element inside debates element if title text is "House of Commons"' do
    tranform_xml(%Q|<hs_3MainHdg UID="a_uid" url="a_url">House of Commons</hs_3MainHdg>|)
    assert_correct('<title>House of Commons</title>')
  end

  it 'should remove SmallCaps element' do
    tranform_xml(%Q|<hs_76fChair UID="a_uid" url="a_url">[<SmallCaps>Mr. Speaker</SmallCaps>
            <I> in the Chair</I>]</hs_76fChair>|)
    assert_correct('<p id=\'a_uid\'>[<span class=\'SmallCaps\'>Mr. Speaker</span><i> in the Chair</i>]</p>')
  end

  it 'should move column out of title element' do
    tranform_xml(%Q|<hs_2cStatement UID="a_uid" alt="Northern Rock" url="a_url">
            <?notus-xml column=21?>Northern Rock</hs_2cStatement>|)

    assert_correct('<col>21</col><title>Northern Rock</title>', ignore=['section','debates'])
  end

  it 'should move column out of title element but keep col and title element in section wrapper element' do
    tranform_xml(%Q|<hs_2cStatement UID="a_uid" alt="Northern Rock" url="a_url">
            <?notus-xml column=21?>Northern Rock</hs_2cStatement>|)

    assert_correct('<col>21</col><section><title>Northern Rock</title></section>', ignore=['debates'])
  end

  it 'should create member contribution' do
    tranform_xml(%Q|<hs_Para
        UID="a_uid"
        tab="yes"
        url="a_url">
        <B>
          <Member
            ContinuationText="Mr. Darling"
            PimsId="a_pims_id"
            UID="a_uid_2"
            xid="a_xid"
            url="a_url_anchor">Mr. Darling:</Member>
        </B> The right hon. Gentleman is right
          <?notus-xml column=29?>that is one policy that they are advocating.</hs_Para>|)

    assert_correct('<p id=\'a_uid\'>
      <member>Mr. Darling</member><membercontribution>: The right hon. Gentleman is right
      <col>29</col>that is one policy that they are advocating.</membercontribution></p>')
  end

  it 'should add lb for paragraph breaks in member contribution' do
    tranform_xml(%Q|<hs_Para
        UID="a_uid"
        tab="yes"
        url="a_url">
        <B>
          <Member
            ContinuationText="James Purnell"
            PimsId="a_pims_id"
            UID="a_uid_2"
            xid="a_xid"
            url="a_url_anchor">James Purnell:</Member>
          </B> I wish to start by paying tribute to </hs_Para>
        <hs_Para
          UID="a_uid_3"
          tab="yes"
          url="a_url_anchor_2">I congratulate the centre.</hs_Para>|)

    assert_correct('<p id=\'a_uid\'>
      <member>James Purnell</member><membercontribution>: I wish to start by paying tribute to <lb/>I congratulate the centre.</membercontribution></p>')
  end

  it 'should remove bold element tags inside member element tags' do
    tranform_xml(%Q|<hs_Para
        UID="a_uid"
        tab="yes"
        url="a_url">
        <Member
          ContinuationText="Chris Grayling"
          PimsId="a_pims_id"
          UID="a_uid_2"
          xid="a_xid"
          url="a_url_anchor">
            <B>Chris Grayling</B> (Epsom and Ewell) (Con):</Member> I welcome the Secretary of State to his position and look </hs_Para>
          <hs_Para
          UID="a_uid_3"
          tab="yes"
          url="a_url_anchor_2">Are the Government on track</hs_Para>|)

    assert_correct('<p id=\'a_uid\'>
      <member>Chris Grayling (Epsom and Ewell) (Con)</member><membercontribution>: I welcome the Secretary of State to his position and look  <lb/>Are the Government on track</membercontribution></p>')
  end

  it 'should format question in to paragraph' do
    tranform_xml(%Q|<Question>
        <hs_Para UID="a_uid" tab="yes" url="a_url">
          <Number>1</Number>. <Member ContinuationText="Ms Celia Barlow" PimsId="a_pims_id" UID="a_uid_2" xid="a_xid" url="a_url_2"><B>Ms Celia Barlow</B> (Hove) (Lab):</Member>
          <QuestionText>What steps he proposes to take. </QuestionText>
          <Uin>[186542]</Uin>
        </hs_Para>
      </Question>|)

    assert_correct('<p id=\'a_uid\'>1. <member>Ms Celia Barlow (Hove) (Lab)</member><membercontribution>: What steps he proposes to take. [186542]</membercontribution></p>')
  end

  it 'should move colon out of text in member element' do
    tranform_this_xml %Q|<hs_Para><B><Member>The
Secretary of State for Work and Pensions (James
Purnell):</Member></B> The Government see a vital
role</hs_Para>|

    @transformed.should == '<housecommons>
<p><member>The
Secretary of State for Work and Pensions (James
Purnell)</member><membercontribution>: The Government see a vital
role</membercontribution></p></housecommons>'
  end

  it 'should record house from name attribute in House element ' do
    @transformer.stub!(:open_source).and_return xml('<HansardDoc><House name="Commons"></House></HansardDoc>')
    @transformed = @transformer.transform
    @transformer.house.should == 'commons'
  end

  it 'should record volume number from volume attribute in Cover element' do
    tranform_xml(%Q|<Cover volume="472"></Cover>|)
    @transformer.volume.should == '472'
  end

  it 'should record part number from part attribute in Cover element' do
    tranform_xml(%Q|<Cover part="1"></Cover>|)
    @transformer.part.should == '1'
  end

  it 'should record part number as "0" if part attribute is missing from Cover element' do
    tranform_xml(%Q|<Cover></Cover>|)
    @transformer.part.should == '0'
  end

  it 'should record date from date processing instruction' do
    tranform_xml '<?date 2008-02-18?>'
    @transformer.date.should == '2008-02-18'
  end

  it 'should construct house_date_identifier from date and house' do
    tranform_xml '<?date 2008-02-18?>'
    @transformer.house_date_identifier.should == 'housecommons_2008_02_18'
  end

  it 'should construct series_volume_identifier from house, volume and part number + a supplied series number' do
    tranform_xml(%Q|<Cover volume="472" part="1"></Cover>|)
    @transformer.series_volume_identifier(:series=>'6').should == 'SC6V0472P1'
  end

  it 'should construct result file name using house_date_identifier and series_volume_identifier' do
    @transformer.stub!(:house_date_identifier).and_return 'housecommons_2008_02_18'
    path = @result_directory + '/housecommons_2008_02_18/SC6V0472P1'
    @transformer.stub!(:result_path).and_return path

    @transformer.result_file.should == path + '/housecommons_2008_02_18.xml'
  end

  it 'should construct result file path using house_date_identifier and series_volume_identifier' do
    @transformer.stub!(:house_date_identifier).and_return 'housecommons_2008_02_18'
    @transformer.stub!(:series_volume_identifier).and_return 'SC6V0472P1'

    @transformer.result_path.should == @result_directory + '/housecommons_2008_02_18/SC6V0472P1'
  end

  it 'should not put "House of Commons" title inside debates element' do
    tranform_xml '<hs_3MainHdg UID="a_uid" url="a_url">House
of Commons</hs_3MainHdg>'
    @transformed.should == "<housecommons>\n<title>House of Commons</title></housecommons>"
  end

  it 'should convert a hs_6bFormalmotion element to a title element in a section' do
    tranform_xml '<hs_6bFormalmotion UID="0801296000003" url="/pa/cm200708/cmhansrd/cm080128/debtext/80128-0022.htm#0801296000003">COMMITTEES</hs_6bFormalmotion>'
    assert_correct '<section><title>COMMITTEES</title></section>', ignore=['debates']
  end

  it 'should convert a hs_7Bill element to a paragraph element' do
    tranform_xml '<hs_7Bill UID="a_uid" url="a_url"><SmallCaps>Canterbury City Council Bill</SmallCaps></hs_7Bill>'
    assert_correct "<p id='a_uid'><span class='SmallCaps'>Canterbury City Council Bill</span></p>"
  end

  it 'should wrap oral questions in oralquestions element until a hs_2cStatement is hit' do
    tranform_xml '<hs_3OralAnswers UID="a_uid">Oral Answers to Questions</hs_3OralAnswers>
    <hs_6bDepartment UID="a_uid_2"><DepartmentName>Children, Schools and Families</DepartmentName></hs_6bDepartment>
    <hs_2cStatement UID="a_uid_3">Speaker’s Statement</hs_2cStatement>'
    assert_correct '<debates><oralquestions><title>Oral Answers to Questions</title><title>Children, Schools and Families</title></oralquestions><title>Speaker’s Statement</title></debates>', ignore=['section']
  end

  it 'should add a quote to a previous membercontribution element if the quote is not in a paragraph' do
    tranform_xml '<hs_Para><B><Member>Andy Burnham:</Member></B> On diversity, McMaster says:</hs_Para><hs_brev UID="a_uid" tab="yes" url="a_url">“We live in one”</hs_brev>'

    assert_correct '<p><member>Andy Burnham</member><membercontribution>: On diversity, McMaster says: <quote>“We live in one”</quote></membercontribution></p>'
  end

  it 'should add a quote to a previous paragraph element if the quote is not in a paragraph' do
    tranform_xml '<hs_Para>On diversity, McMaster says:</hs_Para><?notus-xml column=21?><hs_brev UID="a_uid" tab="yes" url="a_url">“We live in one”</hs_brev>'

    assert_correct '<p>On diversity, McMaster says:<col>21</col> <quote>“We live in one”</quote></p>'
  end

  it 'should add a quote to a previous paragraph element if the quote is not in a paragraph' do
    tranform_xml '<hs_Para>On diversity, McMaster says:</hs_Para><hs_brev UID="a_uid" tab="yes" url="a_url">“We live in one”</hs_brev>'

    assert_correct '<p>On diversity, McMaster says: <quote>“We live in one”</quote></p>'
  end

  it 'should add a quote to a previous paragraph when the quote contains a child element' do
    tranform_this_xml '<hs_Para UID="a_uid"><Number>T3</Number>. <Uin>[182493]</Uin> <Member><B>Tom Brake</B> (Carshalton and Wallington) (LD):</Member>
<QuestionText></QuestionText>In the words of </hs_Para><hs_brev>“serves the community”—[<I>Official Report, </I>5 July 2006; Vol. 448, c.277WH.]</hs_brev>'

    @transformed.should == "<housecommons>
<p id='a_uid'>T3. [182493] <member>Tom Brake (Carshalton and Wallington) (LD)</member><membercontribution>:
 In the words of  <quote>“serves the community”—[<i>Official Report, </i>5 July 2006; Vol. 448, c.277WH.]</quote></membercontribution></p></housecommons>"
  end

  it 'should add a paragraph without a member to the preceding paragraph' do
    xml = '<hs_Para UID="a_uid" tab="yes" url="a_url"><Member ContinuationText="Mr. Michael Fallon" PimsId="3183" UID="a_uid_2" xid="195" url="a_url_2"><B>Mr.
Michael Fallon</B> (Sevenoaks) (Con):</Member> I beg to move, That the
Bill be now read a Second time.</hs_Para>
<hs_Para UID="a_uid_3" tab="yes" url="a_url_3">I am grateful for the wide
support that the Bill has received</hs_Para>'
    @transformer.stub!(:open_source).and_return xml('<HansardDoc><House name="Commons">'+xml+'</House></HansardDoc>')
    @transformed = @transformer.transform

    @transformed.should == %Q|<housecommons>
<p id='a_uid'><member>Mr.
Michael Fallon (Sevenoaks) (Con)</member><membercontribution>: I beg to move, That the
Bill be now read a Second time.<lb/>I am grateful for the wide
support that the Bill has received</membercontribution></p>\n\n</housecommons>|
  end

  it 'should not add a paragraph with a member to the preceding paragraph' do
    xml = '<hs_Para UID="a_uid" tab="yes" url="a_url"><Member ContinuationText="Mr. Michael Fallon" PimsId="3183" UID="a_uid_2" xid="195" url="a_url_2"><B>Mr.
Michael Fallon</B> (Sevenoaks) (Con):</Member> I beg to move, That the
Bill be now read a Second time.</hs_Para><hs_Para UID="a_uid_3" tab="yes" url="a_url_3"><Member ContinuationText="Mr. Tim Boswell" PimsId="4086" UID="a_uid_4" xid="57" url="a_url_4"><B>Mr.
Tim Boswell</B> (Daventry) (Con):</Member> Will my hon. Friend take it
from me</hs_Para>'
    @transformer.stub!(:open_source).and_return xml('<HansardDoc><House name="Commons">'+xml+'</House></HansardDoc>')
    @transformed = @transformer.transform

    @transformed.should == %Q|<housecommons>
<p id='a_uid'><member>Mr.
Michael Fallon (Sevenoaks) (Con)</member><membercontribution>: I beg to move, That the
Bill be now read a Second time.</membercontribution></p>
<p id='a_uid_3'><member>Mr.
Tim Boswell (Daventry) (Con)</member><membercontribution>: Will my hon. Friend take it
from me</membercontribution></p></housecommons>|
  end

  it 'should move house divided text in to a paragraph outside of division element' do
    xml = %Q|<hs_Para UID="uid_1" tab="yes"><I>Question put</I>, That the Bill be now read a Second time:—</hs_Para>
<Division UID="uid_2">
<hs_Para UID="uid_3" tab="yes"><I>The
House divided:</I> Ayes <AyesNumber>45</AyesNumber>, Noes <NoesNumber>0</NoesNumber>.</hs_Para></Division>|
    tranform_xml xml
    assert_correct "<p id='uid_1'><i>Question put</i>, That the Bill be now read a Second time:—</p>
<p id='uid_3'><i>The House divided:</i> Ayes <span class='AyesNumber'>45</span>, Noes <span class='NoesNumber'>0</span>.</p><division><table></table></division>"
  end

  it 'should put division number and time in to two cells of a table row' do
    xml = %Q|<Division UID="uid_2">
<hs_Para UID="08012542000232" url="08012542000232"><B>Division
No.
</B><B><Number>054</Number></B><B>]</B><Right><B>[</B><B><Time>11.56
am</Time></B></Right></hs_Para></Division>|
    tranform_xml xml
    assert_correct %Q|<division><table><tr>
<td>Division No. 054]</td>
<td align='right'>[11.56 am</td>
</tr></table></division>|
  end

  it 'should create row for AYES table heading' do
    xml = %Q|<Division UID="uid_2">
<hs_DivListHeader><B>AYES</B></hs_DivListHeader></Division>|
    tranform_xml xml
    assert_correct %Q|<division><table><tr>
<td align='center' colspan='2'>AYES</td>
</tr></table></division>|
  end

  it 'should create rows for members in NamesAyes element' do
    xml = %Q|<Division UID="uid_2">
<TwoColumn><NamesAyes IsDone="True"><hs_Para UID="08012542000233"><Member PimsId="3609" UID="08012542000668" xid="5">Ainsworth,
Mr.
Peter</Member></hs_Para><hs_Para UID="08012542000234"><Member PimsId="3858" UID="08012542000669" xid="25">Baldry,
Tony</Member></hs_Para><hs_Para UID="08012542000277"><Member PimsId="4611" UID="08012542000712" xid="634">Willetts,
Mr.
David</Member></hs_Para></NamesAyes><TwoColumn></Division>|
    tranform_xml xml
    assert_correct %Q|<division><table><tr>
<td>Ainsworth, Mr. Peter</td>
<td>Baldry, Tony</td>
</tr>
<tr>
<td>Willetts, Mr. David</td>
</tr>
</table></division>|
  end

  it 'should create rows for tellers in TellerNamesAyes element' do
    xml = %Q|<Division UID="uid_2">
<TwoColumn><hs_Para UID="08012542000278"><B>Tellers
for the
Ayes:</B></hs_Para><TellerNamesAyes><hs_Para UID="08012542000279"><B><Member PimsId="907" UID="08012542000713" xid="263">Mr.
Oliver Heald</Member></B><B>
and</B></hs_Para><hs_Para UID="08012542000280"><B><Member PimsId="3912" UID="08012542000714" xid="32">John
Battle</Member></B></hs_Para></TellerNamesAyes><TwoColumn></Division>|
    tranform_xml xml
    assert_correct %Q|<division><table><tr>
<td/>
<td>Tellers for the Ayes:</td>
</tr>
<tr>
<td/>
<td>Mr. Oliver Heald and John Battle</td>
</tr>
</table></division>|
  end

  it 'should close division correctly' do
    xml = %Q|<Division><hs_DivListHeader><B>NOES</B></hs_DivListHeader><TwoColumn><hs_Para><I> </I></hs_Para><hs_Para><I> </I></hs_Para><hs_Para><I> </I></hs_Para><NamesNoes IsDone="True"></NamesNoes><hs_Para UID="08012542000281" url="08012542000281"><B>Tellers
for the
Noes:</B></hs_Para><TellerNamesNoes><hs_Para UID="08012542000282" url="08012542000282"><B><Member PimsId="484" UID="08012542000715" xid="514" url="08012542000715">Mr.
Frank Roy</Member></B><B>
and</B></hs_Para><hs_Para UID="08012542000283" url="08012542000283"><B><Member PimsId="1771" UID="08012542000716" xid="375" url="08012542000716">Steve
McCabe</Member></B></hs_Para></TellerNamesNoes></TwoColumn><hs_Para UID="08012542000284" tab="yes" url="08012542000284"><I>Question
accordingly agreed to.</I></hs_Para></Division>|
    tranform_xml xml
    assert_correct %Q|<division>
<table>
<tr><td align='center' colspan='2'>NOES</td></tr>
<tr><td/><td>Tellers for the Noes:</td></tr>
<tr><td/><td>Mr. Frank Roy and Steve McCabe</td>
</tr>
</table>
</division>
<p id='08012542000284'><i>Questionaccordingly agreed to.</i></p>|
  end
end