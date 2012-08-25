require File.dirname(__FILE__) + '/../../spec_helper'

def H text
  Hpricot text
end

describe Hansard::HouseParser do
  
  before do 
    @parser = Hansard::HouseParser.new ''
    @parser.stub!(:anchor_id)
  end 
  
  describe 'in general' do 
    
    it 'should return series_number using source_file' do
      number = 4
      parser = Hansard::HouseParser.new '', nil, mock(SourceFile, :series_number => number)
      parser.series_number.should == number
    end

  end
  
  describe 'when root element is not recognized' do
    
    it 'should raise an exception' do
      doc = mock('doc')
      @parser.stub!(:load_doc).and_return doc
      @parser.should_receive(:get_root_name).with(doc).and_return 'random_element'
      lambda { @parser.parse }.should raise_error(Exception, /unrecognized type/)
    end
  
  end

  describe 'handling empty titles' do
    it 'should raise an error when finding a blank title before speaker in chair line' do
      section = H '<debates><section><title></title>
                   <p id="S5CV0378P0-02535" align="center">[Mr. SPEAKER <i>in the Chair.</i>]</p>
                   <p>More debate text</p>
                   </section></debates>'
      lambda { @parser.handle_section section.at('section'), mock('debates') }.should raise_error
    end

    it 'should ignore empty title when section contains no text' do
      section = H '<debates><section><title></title></section></debates>'
      lambda { @parser.handle_section section.at('section'), mock('debates') }.should_not raise_error
    end

    it 'should raise exception when section contains text' do
      section = H '<debates><section><title></title><p>Stuff</p></section></debates>'
      lambda { @parser.handle_section section.at('section'), mock('debates') }.should raise_error
    end
  end

  describe "when creating a sitting" do
    it 'should create the sitting on the date in the filename rather than the date from the xml if the two differ' do
      data_file = mock_model(DataFile)
      HouseOfCommonsSitting.should_receive(:new).with({:date=>"1889-08-21",
                                                       :date_text=>"Wednesday, 21st August, 1889.",
                                                       :title=>"HOUSE OF COMMONS,",
                                                       :start_column=>"1", 
                                                       :data_file => data_file}).and_return(mock_model(Sitting, :null_object => true))
      parse_hansard_file(Hansard::CommonsParser, data_file_path('housecommons_1889_08_21.xml'), data_file)
    end
  end

  describe 'when extracting the chairman from chairman text' do
    
    def chairman_should_be(chair_text, chairman)
      @parser.get_chairman(chair_text).should == chairman
    end

    it 'should get "MR. SPEAKER" from "[MR. SPEAKER in the Chair]"' do
      chairman_should_be '[MR. SPEAKER in the Chair]', 'MR. SPEAKER'
    end

    it 'should get "Mr. SPEAKER" from "\r\nThe House met at a Quarter before Three of the Clock, Mr. SPEAKER in the Chair.\r\n"' do
      chairman_should_be "\r\nThe House met at a Quarter before Three of the Clock, Mr. SPEAKER in the Chair.\r\n", 'Mr. SPEAKER'
    end

    it 'should get "SIR NICHOLAS WINTERTON" from "[SIR NICHOLAS WINTERTON in the Chair]"' do
      chairman_should_be '[SIR NICHOLAS WINTERTON in the Chair]', 'SIR NICHOLAS WINTERTON'
    end

    it 'should get "The Deputy Chairman of Committees (Lord Ampthill)" from "[The Deputy Chairman of Committees (Lord Ampthill) in the Chair.]"' do
      chairman_should_be '[The Deputy Chairman of Committees (Lord Ampthill) in the Chair.]', 'The Deputy Chairman of Committees (Lord Ampthill)'
    end
    
  end

  describe 'when parsing a file with two debates tags' do
    before(:each) do
      file = 'housecommons_two_debates.xml'
      stub_model_methods
      @parser =  Hansard::CommonsParser.new(data_file_path(file), nil, nil)
    end

    it 'should handle the debates tag twice' do
      @parser.should_receive(:handle_debates).exactly(2).times
      @parser.parse
    end

    it 'should create a debates section once' do
      @parser.stub!(:create_section).and_return(mock_model(Section, :null_object => true))
      @parser.should_receive(:create_section).with(Debates).and_return(mock_model(Debates, :null_object => true))
      @parser.parse
    end
  end

  describe 'when handling question contributions' do
    before do
      file = data_file_path('housecommons_empty.xml')
      @parser = Hansard::HouseParser.new(file)
      @parser.stub!(:set_columns_and_images_on_contribution)
      @parser.stub!(:anchor_id)
      @section = mock_model(Section, :contributions => [])
      @section.stub!(:add_contribution)
    end

    it 'should append text in a bold tag between the member and member contribution tags to the member text' do
      doc = Hpricot('<p id="S6CV0337P0-02666"><member>Mr. Stuart Bell</member><b> (Second Church Estates Commissioner, representing the Church Commissioners)</b><membercontribution>: The issue of whether commissioners\' land should be leased to allow trials of genetically modified crops to take place is being considered
      <image src="S6CV0337P0I0352"/>
      <col>689</col>
      initially by the Church\'s ethical investment working group, which develops a co-ordinated ethical investment policy for the Church.</membercontribution></p>')
      element = doc.at('p')
      contribution = @parser.handle_question_contribution(element, @section)
      contribution.member_name.should == "Mr. Stuart Bell (Second Church Estates Commissioner, representing the Church Commissioners)"
    end

    it "should append text in a 'sup' tag before the membercontribution to the contribution prefix" do
      doc = Hpricot('<p id="S4V0107P0-00220"><sup>*</sup><member>THE FIRST LORD OF THE ADMIRALTY (THE EARL OF SELBORNE)</member><membercontribution>: My Lords, I am sure my noble friend will do mo the justice of believing that my previous reply was not meant to convey any want of respect to him personally, but I do think that the very peculiar nature of the questions he asked justified the rather peculiar nature of my reply. </membercontribution></p>')
      element = doc.at('p')
      contribution = @parser.handle_question_contribution(element, @section)
      contribution.prefix.should == '<sup>*</sup>'
    end
  
    it 'should treat numbers in square brackets at the end of the contribution as part of the text' do 
      doc = Hpricot('<p>3. <member>Mr. Michael Jack <memberconstituency>(Fylde) (Con)</memberconstituency></member><membercontribution>: If she will make a statement on the proposals to implement the revised common agricultural policy.</membercontribution> [152865]</p>')
      element = doc.at('p')
      contribution = @parser.handle_question_contribution(element, @section)
      contribution.text.should == ': If she will make a statement on the proposals to implement the revised common agricultural policy. [152865]'
    end

    it "should raise an exception for a 'sup' tag between the member and membercontribution" do
      doc = Hpricot('<p id="S4V0095P0-02541"><member>MR. WYNDHAM</member><sup>*</sup><membercontribution>: I am afraid I cannot add to the replies to similar questions which the hon. Member addressed to me on the 19th and 21st February last.</membercontribution></p>')
      element = doc.at('p')
      lambda{ contribution = @parser.handle_question_contribution(element, @section) }.should raise_error('Unhandled element in Question contribution    sup    <sup>*</sup>')
    end

    it "should add text in a 'sup' tag in the membercontribution to the contribution text" do
      doc = Hpricot('<p id="S4V0095P0-02541"><member>MR. WYNDHAM</member><membercontribution>: I am afraid I cannot add to the replies to similar questions which the hon. Member addressed to me on the 19th and 21st February last.<sup>*</sup></membercontribution></p>')
      element = doc.at('p')
      contribution = @parser.handle_question_contribution(element, @section)
      contribution.text.should == ': I am afraid I cannot add to the replies to similar questions which the hon. Member addressed to me on the 19th and 21st February last.<sup>*</sup>'
    end

    it "should add text in a 'sup' tag after the membercontribution to the contribution text" do
      doc = Hpricot('<p id="S4V0095P0-02541"><member>MR. WYNDHAM</member><membercontribution>: I am afraid I cannot add to the replies to similar questions which the hon. Member addressed to me on the 19th and 21st February last.</membercontribution><sup>*</sup></p>')
      element = doc.at('p')
      contribution = @parser.handle_question_contribution(element, @section)
      contribution.text.should == ': I am afraid I cannot add to the replies to similar questions which the hon. Member addressed to me on the 19th and 21st February last.<sup>*</sup>'
      contribution.prefix.should be_nil
    end

    it "should append an asterisk before the member name to the contribution prefix" do
      doc = Hpricot('<p id="S4V0126P0-00330">*<member>SIR CHARLES DILKE <memberconstituency>(Gloucestershire, Forest of Dean)</memberconstituency></member><membercontribution>: Is there not a Transvaal Commission as well?</membercontribution></p>')
      element = doc.at('p')
      contribution = @parser.handle_question_contribution(element, @section)
      contribution.prefix.should == '*'
      contribution.text.should == ': Is there not a Transvaal Commission as well?'
    end
  
    it 'should set an anchor id on the contribution' do 
      doc = Hpricot('<p><member></member><membercontribution></membercontribution>')
      element = doc.at('p')
      @parser.should_receive(:anchor_id).and_return('anchor id')
      contribution = @parser.handle_question_contribution(element, @section)
      contribution.anchor_id.should == 'anchor id'
    end
  
    it 'should set the start and end images on the contribution' do 
      @parser.stub!(:image).and_return('test image')
      doc = Hpricot('<p><member></member><membercontribution></membercontribution>')
      element = doc.at('p')
      contribution = @parser.handle_question_contribution(element, @section)
      contribution.start_image.should == 'test image'
      contribution.end_image.should == 'test image'     
    end
    
    it 'should handle italicized text directly in the paragraph after raw text' do 
      doc = Hpricot('<p id="S5CV0019P0-00886"><member>Mr. McKENNA</member>: The reply to the first part of the question is:&#x2014;
      <i>yes!</i></membercontribution>')
      element = doc.at('p')
      contribution = @parser.handle_question_contribution(element, @section)
      contribution.text.should == ': The reply to the first part of the question is:&#x2014;<i>yes!</i>'
    end
    
    it 'should handle a table directly in the paragraph' do 
      doc = Hpricot('<p id="S5CV0019P0-00886"><member>Mr. McKENNA</member>: The reply to the first part of the question is:&#x2014;
      <table>
      <tr>
      <td>United Kingdom</td>
      <td align="right">32</td>
      </tr>
      <tr>
      <td>Germany</td>
      <td align="right">9</td>
      </tr></table></membercontribution>')
      element = doc.at('p')
      contribution = @parser.handle_question_contribution(element, @section)
      contribution.text.should == ': The reply to the first part of the question is:&#x2014;<table>
      <tr>
      <td>United Kingdom</td>
      <td align="right">32</td>
      </tr>
      <tr>
      <td>Germany</td>
      <td align="right">9</td>
      </tr></table>'
    end
    
  end
  

  describe 'when handling a division' do
  
    def expect_headers division_text, headers
      node = Hpricot(division_text)
      section = mock_model(Section, :contributions => [])
      data_file = mock_model(DataFile, :add_log => true, :log_exception => true)
      parser = Hansard::HouseParser.new '', data_file
      placeholder = mock_model(DivisionPlaceholder, :have_a_complete_division? => false)
      parser.should_receive(:create_division_placeholder).with(node, section, headers).and_return(placeholder) 
      parser.handle_division(node, section)
    end
  
    it 'should extract header values from a table with headers in <th> tags' do 
      division_text = '<table><tr><th>first header</th><th>second header</th></tr></table>'
      expect_headers division_text, ['first header', 'second header']
    end
  
    it 'should extract header values from a table with headers in <td> tags' do 
      division_text = '<table><tr><td>first header</td><td>second header</td></tr></table>'
      expect_headers division_text, ['first header', 'second header']
    end
  
  end

  describe 'when handling a division table' do 
  
    def setup_table table_text
      @table = Hpricot(table_text)
      @parser.stub!(:division_table_width).and_return(2)
      @division = mock_model(Division)
    end

    it 'should ask for cells that are table headers to be handled' do 
      table_text = '<table><tr><th>cell one</th><th>cell two</th></tr></table>'
      setup_table table_text
      cell_one = @table.at('th[1]')
      cell_two = @table.at('th[2]')
      @parser.should_receive(:handle_division_table_cell).with(cell_one, @division, [cell_two], nil)
      @parser.should_receive(:handle_division_table_cell).with(cell_two, @division, [cell_two], nil)
      @parser.handle_division_table @table, @division 
    end
  
  
    it 'should ask for cells that are table data to be handled' do 
      table_text = '<table><tr><td>cell one</td><td>cell two</td></tr></table>'
      setup_table table_text
      cell_one = @table.at('td[1]')
      cell_two = @table.at('td[2]')
      @parser.should_receive(:handle_division_table_cell).with(cell_one, @division, [cell_two], nil)
      @parser.should_receive(:handle_division_table_cell).with(cell_two, @division, [cell_two], nil)
      @parser.handle_division_table @table, @division 
    end
  
    it 'should not throw an error when there is an extra cell in a row' do 
      table_text = "<table>
      <tr>
      <td><b>Division No.87]</b></td>
      <td align=\"right\"><b>[6.57 am</b></td>
      </tr>
      <tr>
      <td>Coffey, Ms Ann</td><td></td>
      <td>Coleman, lain</td>
      </tr>
      </table>"
      setup_table table_text
      @parser.stub!(:division_table_width).and_return(2)
      @parser.stub!(:handle_the_vote)
      @parser.handle_division_table @table, @division
    end
  
  end
  
  describe 'when handling a question contribution element' do 
    
    it 'should handle an "ob" tag by adding it to the contribution text' do
      text = '<p id="S5CV0159P0-04682"><member>Major TRYON</member>: I civil practition<ob/></p>'
      element = Hpricot(text).at('p')
      node = element.at('ob')
      contribution = mock_model(Contribution, :text => ': I civil practition')
      contribution.should_receive(:text=).with(': I civil practition<ob></ob>')
      @parser.handle_element_in_question_contribution(node, contribution, element, :in_contribution)
    end
    
  end
  

  describe 'when handling a division table cell' do
  
    before do 
      @teller_heading = %Q|TELLERS FOR THE NOES|
      @filler = %Q|&#x2014;|
      @cell = H("<td><b>#{@teller_heading}</b>#{@filler}</td>").at('td')
      @division = mock('division')
      @last_column_cells = mock('last_column_cells')
      @parser = Hansard::HouseParser.new ''
    end
 
    it 'should handle text inside bold element' do
      @parser.should_receive(:handle_the_vote).with(@teller_heading, @cell, @division, @last_column_cells, nil)
      @parser.should_not_receive(:handle_the_vote).with(@filler, @cell, @division, @last_column_cells)
      @parser.handle_division_table_cell(@cell, @division, @last_column_cells, nil)
    end
    
    it 'should not handle votes if it has no division handler' do 
      @parser.stub!(:division_handler).and_return(false)
      @parser.should_not_receive(:handle_the_vote)
      @parser.handle_division_table_cell(@cell, @division, @last_column_cells, nil)
    end

  end
  
  describe 'when handling a paragraph' do 
  
    before do 
      @parser.stub!(:handle_procedural_contribution)
    end
    
    it 'should handle a time contribution if the text is "7.30 pm"' do 
      text = "<p>7.30 pm</p>"
      node = Hpricot(text).at('p')
      @parser.should_receive(:handle_time_contribution)
      @parser.handle_paragraph(node, mock_model(Section))
    end
    
    it 'should not handle a time contribution if the text of one line is "7.30 pm"' do
      text = "<p>demand that the Greater London council should pay over this money to him.<lb/>
7.30 pm
I want to draw the Committee's attention to the fact</p>"
      node = Hpricot(text).at('p')
      @parser.should_not_receive(:handle_time_contribution)
      @parser.handle_paragraph(node, mock_model(Section))
    end
    
  end

  describe 'when handling member contributions' do
    before do
      file = data_file_path('housecommons_empty.xml')
      @parser = Hansard::HouseParser.new(file)
      @parser.stub!(:anchor_id).and_return('the anchor id')
      @parser.stub!(:image).and_return('test image')
      @parser.stub!(:set_columns_and_images_on_contribution)
      @section = mock_model(Section, :contributions => [])
      @section.stub!(:add_contribution)
    end
  
    def handle_contribution text 
      doc = Hpricot(text)
      element = doc.at('p')
      contribution = @parser.handle_member_contribution(element, @section)
    end

    it "should append an asterisk before the member name to the contribution prefix" do
      doc = '<p id="S4V0126P0-00209">*<member>THE LORD CHANCELLOR (The Earl of HALSBURY)</member><membercontribution>: I think it would be more convenient.</membercontribution></p>'
      contribution = handle_contribution(doc)
      contribution.prefix.should == '*'
      contribution.text.should == ': I think it would be more convenient.'
    end

    it 'should handle text after a member tag and before a membercontribution tag by adding it to the procedural note' do 
      doc = '<p><member>Mr. Spencer Stanhope</member>, <membercontribution>who stated that he had long</p>'
      contribution = handle_contribution(doc)
      contribution.member_name.should == 'Mr. Spencer Stanhope'
      contribution.procedural_note.should == ', '
      contribution.text.should == 'who stated that he had long'
    end
  
    it 'should handle "The" before the member tag, by adding it to the prefix' do 
      doc = '<p>The <member>Speaker</member> <membercontribution>acquainted the house, </membercontribution></p>'
      contribution = handle_contribution(doc)
      contribution.member_name.should == 'The Speaker'
      contribution.prefix.should be_nil
    end
  
    it 'should set an anchor id on the contribution' do 
      doc = '<p>The <member>Speaker</member> <membercontribution>acquainted the house, </membercontribution></p>'
      contribution = handle_contribution(doc)
      contribution.anchor_id.should == 'the anchor id'
    end

    it 'should set the start and end image on the contribution' do 
      doc = '<p>The <member>Speaker</member> <membercontribution>acquainted the house, </membercontribution></p>'
      contribution = handle_contribution(doc)
      contribution.start_image.should == 'test image'
      contribution.end_image.should == 'test image'
    end
    
    it 'should handle a contribution with no text' do 
      doc = '<p id="S5LV0646P0-00801"><member>Baroness Miller of Hendon</member> moved Amendment No. 11:</p>'
      contribution = handle_contribution(doc)
      contribution.member_name.should == 'Baroness Miller of Hendon'
      contribution.procedural_note.should == ' moved Amendment No. 11:'
    end
    
  end

  describe 'when handling division table missing division element' do
    before do
      @header_values = ['NOES']
      html = %Q|<table><tr><td colspan="3">#{@header_values.first}</td></tr>
                       <tr><td>Ait</td><td>Ben</td><td>Bro</td></tr></table>|
      @parser = Hansard::HouseParser.new ''
      @table = H(html).at('table')
      @section = mock_model(Section)
    end

    it 'should recognize pass table node to handle_table_or_division method' do
      @parser.should_receive(:handle_table_or_division).with(@table, @section)
      @parser.handle_section_element_children @table, @section
    end

    it 'should recognize division and handle as such' do
      year = '2008'
      @parser.stub!(:year).and_return year
      @parser.should_not_receive(:handle_table_element)
      @parser.should_receive(:start_of_division?).with(year, @header_values, nil).and_return false
      division_element = mock('division_element')
      @parser.should_receive(:wrap_as_division).with(@table).and_return division_element
      @parser.should_receive(:handle_division).with(division_element, @section)

      @parser.handle_table_or_division @table, @section
    end
  end

  describe 'when handling nodes in member contributions' do
    
    before do 
      @section = mock_model(Section)
      @contribution = mock_model(Contribution, :prefix=>'')
      @status = :before_member
    end
    
    it 'should call create time contribution when a timestamp is found' do
      time = %Q|(11.19.)|
      xml = "<p>#{time} <member>MR. BYRON REED <memberconstituency>(Bradford, E.)</memberconstituency></member>: <membercontribution>Sir, I should not</p>"
      xml = Hpricot.XML xml
      text_node = xml.at('p').children.first
      @contribution.should_receive(:prefix=).with(@contribution.prefix+time)
      @parser.handle_member_contribution_node @contribution, text_node, @section, @status
    end
    
    it 'should add some text before the member as a prefix' do 
      text = "<p id=\"S5CV0637P0-00873\">65. <member>Sir HAMILTON KERR</member><membercontribution>: To ask the Chancellor of the Exchequer whether he will now announce a decision on the National Theatre.</membercontribution></p>"
      text_node = Hpricot(text).at('p').children.first
      @contribution.should_receive(:prefix=).with(@contribution.prefix+'65.')
      @parser.handle_member_contribution_node @contribution, text_node, @section, @status
    end
    
  end

  describe 'when handling time stamp formatted in old style' do
  
    before do 
      @parser.stub!(:image).and_return('test image')
      @section = mock('section')
      @time_text = '(11.19.)'
      @parser.stub!(:anchor_id).and_return 'anchor id'
      @parser.stub!(:column).and_return 'col'
      @section.stub!(:add_contribution)
    end
    
    it 'should set the anchor id on the contribution' do 
      time_contribution = @parser.handle_time_contribution(nil, @section, @time_text)
      time_contribution.anchor_id.should == 'anchor id'
    end
    
    it 'should set the column range on the contribution to the current column' do 
      time_contribution = @parser.handle_time_contribution(nil, @section, @time_text)
      time_contribution.column_range.should == 'col'
    end
    
    it 'should set the text on the contribution' do
      time_contribution = @parser.handle_time_contribution(nil, @section, @time_text)
      time_contribution.text.should == @time_text
    end

    it 'should add the contribution to the section' do 
      @section.should_receive(:add_contribution)
      @parser.handle_time_contribution nil, @section, @time_text
    end
    
    it 'should set the start and end image on the contribution' do 
      time_contribution = @parser.handle_time_contribution(nil, @section, @time_text)
      time_contribution.start_image.should == 'test image'
      time_contribution.end_image.should == 'test image'     
    end
    
  end

  describe 'when handling MINUTES text in first paragraph' do
    before do
      @title = '[MINUTES.]'
      xml = Hpricot.XML %Q|<debates><section><title></title><p id="S1V0001P0-00760">#{@title}&#x2014;</p></section></debates>|
      @section = xml.at('section')
    end

    it 'should allow parsing to continue' do
      debates = mock('debates')
      @parser.should_receive(:handle_section_element).with(@section, debates)
      @parser.handle_section @section, debates
    end

    it 'should set title from first paragraph text' do
      title = @section.at('title')
      @parser.should_receive(:handle_node_text).with(title).and_return ''
      @parser.should_receive(:handle_node_text).with(title.at('../p[1]')).and_return @title+'&#x2014;'
      section = mock('section', :start_column= => true)
      section.should_receive(:title=).with(@title)
      @parser.handle_title title, section
    end
  end
  
  describe 'when handling a section title' do 
  
    it 'should set the start column for the section to the current column' do
      section_xml = Hpricot.XML'<section><title>The Title</title></section>'
      section = mock_model(Section, :title= => true) 
      title = section_xml.at('title')
      @parser.stub!(:column).and_return(54)
      section.should_receive(:start_column=).with(54)
      @parser.handle_title(title, section)
    end
  
  end

  describe 'when handling sitting with an untitled section' do
    
    before do
      @text = %Q|The various bills before the House|
      @debates = %Q|<debates><section><title></title><p id="S1V0001P0-00760">#{@text}</p></section></debates>|
      xml = Hpricot.XML @debates
      @section = xml.at('section')
    end

    it 'should allow parsing to continue' do
      debates = mock('debates')
      @parser.should_receive(:handle_section_element).with(@section, debates)
      @parser.handle_section @section, debates
    end

    it 'should allow parsing to continue if there are two paragraphs' do
      xml = Hpricot.XML @debates.sub('</section>','<p>wait there is more</p></section')
      debates = mock('debates')
      @parser.stub!(:handle_section_element)
      @parser.handle_section(xml.at('section'), debates)
    end
  
    it 'should set the sitting section title to the MINUTES part of the section text if the text includes "MINUTES"' do 
      title = @section.at('title')
      minutes_text = "[MINUTES.]&#x2014;Sir J. W. Anderson presented the Stratford-le-Bow"
      @parser.should_receive(:handle_node_text).with(title).and_return ''
      @parser.should_receive(:handle_node_text).with(title.at('../p[1]')).and_return minutes_text
      section = mock('section', :start_column= => true)
      section.should_receive(:title=).with('[MINUTES.]')
      @parser.handle_title title, section      
    end
  
    it 'should set the sitting section title to the square bracketed start of the first para if there is one' do 
      title = @section.at('title')
      title_text = "<p><member>[Minutes.]</member> <membercontribution>The Sheriffs of London</membercontribution></p>"
      @parser.should_receive(:handle_node_text).with(title).and_return ''
      @parser.should_receive(:handle_node_text).with(title.at('../p[1]')).and_return title_text
      section = mock('section', :start_column= => true)
      section.should_receive(:title=).with('[Minutes.]')
      @parser.handle_title title, section
    end
  
    it 'should set the sitting section title to the square bracketed start of the first para if there is one' do 
      title = @section.at('title')
      title_text = "<p><member>[Budget.]</member> <membercontribution>On the motion of lord H Petty,"
      @parser.should_receive(:handle_node_text).with(title).and_return ''
      @parser.should_receive(:handle_node_text).with(title.at('../p[1]')).and_return title_text
      section = mock('section', :start_column= => true)
      section.should_receive(:title=).with('[Budget.]')
      @parser.handle_title title, section
    end

    it 'should set sitting section title to "Summary of Day", if text does not include "MINUTES"' do
      title = @section.at('title')
      @parser.should_receive(:handle_node_text).with(title).and_return ''
      @parser.should_receive(:handle_node_text).with(title.at('../p[1]')).and_return @text
      section = mock('section', :start_column= => true)
      section.should_receive(:title=).with('Summary of Day')
      @parser.handle_title title, section
    end
  end

  describe "when handling unparsed divisions" do 
  
    before do 
      @parser.stub!(:anchor_id)
      @placeholder = mock_model(UnparsedDivisionPlaceholder, :section= => true, :anchor_id= => nil)
      UnparsedDivisionPlaceholder.stub!(:new).and_return(@placeholder)
    end
  
    it 'should set the xml id of the unparsed division placeholder to the xml id of the previous contribution in the section' do 
      contribution = mock_model(Contribution, :xml_id => 'xml')
      section = mock_model(Section, :contributions => [contribution])
      node = Hpricot.XML ''
      @placeholder.should_receive(:xml_id=).with('xml')
      @parser.handle_unparsed_division(node, section)
    end
  
    it 'should set the xml id of the unparsed division placeholder to nil if there is no previous contribution in the section' do 
      section = mock_model(Section, :contributions => [])
      node = Hpricot.XML ''
      @placeholder.should_not_receive(:xml_id=)
      @parser.handle_unparsed_division(node, section)
    end
  
    it 'should set the anchor_id of the unparsed division placeholder' do 
      @parser.stub!(:anchor_id).and_return("the anchor id")
      contribution = mock_model(Contribution, :xml_id => 'xml')
      section = mock_model(Section, :contributions => [contribution])
      node = Hpricot.XML ''
      @placeholder.stub!(:xml_id=)
      @placeholder.should_receive(:anchor_id=).with('the anchor id')
      @parser.handle_unparsed_division(node, section)
    end

  end
  
  describe 'when creating a house sitting' do 
  
    it 'should set the current image to the first image in the document' do 
      doc = Hpricot.XML('<housecommons><image src="S5CV0052P0I0005"/>
      <col>1</col>
      <title>HOUSE OF COMMONS.</title></housecommons>')
      @parser.create_house_sitting('housecommons', HouseOfCommonsSitting, doc)
    end
    
  end
  
  describe 'when dealing with anchor_ids' do 
  
    before do 
      source_file = mock_model(SourceFile, :name => "S6CV0417P1")
      data_file = mock_model(DataFile, :source_file => source_file, 
                                       :name => 'westminsterhall_2004_02_12.xml')
      @parser = Hansard::HouseParser.new(nil, data_file, source_file)
      @parser.stub!(:sitting).and_return(mock_model(Sitting, :data_file => data_file, 
                                                             :type_abbreviation => 'WH',
                                                             :short_date => '20040212'))
    end
  
    it_should_behave_like "All parsers"
    
    it 'should give an anchor id of "S6CV0417P1_20040212_WH_1" the first time it is asked for one in the series 6 vol 417 part 1 westminster hall sitting of 12/02/2004' do   
      @parser.anchor_id.should == 'S6CV0417P1_20040212_WH_1'
    end
  
    describe 'when creating a house divided contribution' do 
  
      before do 
        @parser.stub!(:anchor_id).and_return('the anchor id')
        @parser.stub!(:image).and_return('test image')
        @contribution = @parser.create_house_divided_contribution('some text')
      end
      
      it 'should set an anchor id on the contribution' do 
        @contribution.anchor_id.should == 'the anchor id'
      end
      
      it 'should set a start and end image on the contribution' do 
        @contribution.start_image.should == 'test image'
        @contribution.end_image.should == 'test image'
      end
  
    end
    
    describe 'when creating a procedural contribution' do 
    
      before do 
        @parser.stub!(:image).and_return('test image')
        @parser.stub!(:anchor_id).and_return('the anchor id')
        @contribution = @parser.create_procedural_contribution(mock('node', :null_object => true), mock_model(Section))
      end
  
      it 'should set an anchor id on the contribution' do 
        @contribution.anchor_id.should == 'the anchor id'
      end
    
      it 'should set a start and end image on the contribution' do 
        @contribution.start_image.should == 'test image'
        @contribution.end_image.should == 'test image'
      end

    end

    describe 'when creating a division placeholder' do 

      before do 
        @parser.stub!(:anchor_id).and_return('the anchor id')
        @parser.stub!(:year)
        @parser.stub!(:column).and_return('test column')
        @parser.stub!(:image).and_return('test image')
        @parser.stub!(:obtain_division).and_return(Division.new, true)
        @placeholder, is_new_division  = @parser.create_division_placeholder(mock('node', :null_object => true), mock_model(Section), '')
      end

      it 'should set an anchor id on the new contribution' do
        @placeholder.anchor_id.should == 'the anchor id'
      end
      
      it 'should set the column range on the placeholder' do 
        @placeholder.column_range.should == 'test column'
      end
      
      it 'should set the start and end image on the placeholder' do 
        @placeholder.start_image.should == 'test image'
        @placeholder.end_image.should == 'test image'
      end
  
    end

  end
  
end
