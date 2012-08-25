require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::DebatesPreprocessor, "when cleaning files" do 
    
  before do 
    @preprocessor = Hansard::DebatesPreprocessor.new
  end
  
  it 'should set its output file to be the same as its input file if asked to overwrite' do 
    @preprocessor.outfile("my/input/file.xml", overwrite=true).should == "my/input/file.xml"
  end
  
  it 'should set its output file to be its input file with the extra extension ".clean" if asked not to overwrite' do
    @preprocessor.outfile("my/input/file.xml", overwrite=false).should == "my/input/file.xml.clean"
  end 
  
  describe "when grouping content into sections" do 
  
    it 'should not change a document with any section inside the debate tag' do
      node = Hpricot.XML('<root><debates><section></section></debates></root>')
      @preprocessor.group_content_into_sections(node).should == node
    end
    
    it 'should create a new section enclosing a tag inside the debate tag that is identified as a section start' do 
      node = Hpricot.XML('<root><debates><p><member>[Title] Member</member></p><p><member>[Another]</member></p></debates></root>')
      content = @preprocessor.group_content_into_sections(node)
      content.search('root/debates/section').size.should == 2
    end
    
    it 'should remove the title from an identified section start and create a title tag within the section' do 
      node = Hpricot.XML('<root><debates><p><member>[Title] Member</members></p></debates></root>')
      content = @preprocessor.group_content_into_sections(node)
      content.at('root/debates/section/title[text()*=Title]').should_not be_nil
      content.at('root/debates/section/p/member[text()*=Title]').should be_nil
    end
  
    it 'should move standalone image and column tags into the debates tag but shouldn\'t make sections that just contains image and column tags' do
      node = Hpricot.XML('<root><debates><image/><col>11</col></debates></root>')
      content = @preprocessor.group_content_into_sections(node)
      content.to_original_html.should == '<root><debates><image/><col>11</col></debates></root>'
    end
    
  end
  
  
  describe 'when getting a section title from a node' do 
    
    def get_title text
      @node = Hpricot.XML(text).at('element')
      @preprocessor.extract_section_title(@node)
    end
    
    it 'should extract "Title" from a node with text "[Title]"' do
      get_title('<element><member>[Title] boo</member></element>').should == "Title" 
    end
    
    it 'should extract "" from node with text "and this is not the [TITLE]"' do 
      get_title("<element>and this is not the [TITLE]</element>").should == "" 
    end
    
    it 'should extract "TITLE" from "<p><member>TITLE]</member> <membercontribution></membercontribution></p>"' do 
      get_title('<element><member>TITLE]</member> <membercontribution></membercontribution></element>').should == 'TITLE'
    end
    
    it 'should extract "PRAYERS" from a node with text "PRAYERS"' do 
      get_title('<element>PRAYERS</element>')
    end
    
    it 'should leave the remainder of the node text content (stripped of leading/trailing spaces)' do
      get_title('<element><member>[Title] boo</member></element>')
      @node.inner_text.should == 'boo'
    end
    
    it 'should leave the text "boo" when extracting section title from a node with text "[Title]&#x2014; boo"' do 
      get_title('<element><member>[Title]&#x2014; boo</member></element>')
      @node.inner_text.should == 'boo'
    end
    
    it 'should handle a title with a column tag in it' do 
      text = '<element><member>[PETITION FROM BERKS AGAINST AD-
      <col>26</col>
      DITIONAL FORCE BILL.] Mr. Charles Dundas</member></element>'
      get_title(text).should == "PETITION FROM BERKS AGAINST AD- DITIONAL FORCE BILL."
      @node.inner_text.should == 'Mr. Charles Dundas'
    end

    it 'should handle a titlecase title ' do 
      text = "<element><member>[Minutes.]</member> <membercontribution>The Sheriffs of </membercontribution></element>"
      get_title(text).should == 'Minutes.'
      @node.inner_text.should == ' The Sheriffs of '
    end
    
  end
  
  
  describe "when asked whether a node is a minutes section" do 
  
    it 'should return true for a node like "<p id=\"S3V0039P0-02326\">MTNUTES.] Bill. Read a second time:&#x2014;Juries at Quarter Sessions.</p>""' do 
      text = "<p id=\"S3V0039P0-02326\">MTNUTES.] Bill. Read a second time:&#x2014;Juries at Quarter Sessions.</p>"
      node =  Hpricot.XML(text).at('p')
      @preprocessor.is_minutes?(node).should be_true
    end
    
    it 'should return true for a node like "<p id=\"S3V0136P0-02783\">MINUTE.]PUBLIC BILL.&#x2014;1<sup>a</sup> Common Law Procedure.</p>"' do 
      text = "<p id=\"S3V0136P0-02783\">MINUTE.]PUBLIC BILL.&#x2014;1<sup>a</sup> Common Law Procedure.</p>"
      node = Hpricot.XML(text).at('p')
      @preprocessor.is_minutes?(node).should be_true
    end
    
  end
  
  describe "when asked whether a node is a section start" do 
    
    def expect_section text, is_section
      node = Hpricot.XML(text).at('root/')
      if is_section
        @preprocessor.is_section_start?(node).should be_true
      else
        @preprocessor.is_section_start?(node).should be_false
      end
    end
  
    it 'should return false for a text node' do 
      expect_section('<root>moooo</root>', false)
    end
    
    it 'should return false for a node "<root>[Amendment No. 2 not moved.]</root>"' do 
      expect_section('<root>Amendment No. 2 not moved.]</root>', false)
    end
    
    it 'should return false for a non p element' do 
      expect_section('<root><table></table></root>', false)
    end
    
    it 'should return false for a p element with no member child' do 
      expect_section('<root><p><i></i></p></root>', false)
    end
    
    it 'should return false for a p element with member child with no square brackets' do 
      expect_section('<root><p><member>Mr. Jones</member></p></root>', false)
    end
    
    it 'should return true for a p element with member child that has text in square brackets' do
      expect_section('<root><p><member>[TITLE] Mr. Jones</member></p></root>', true)
    end
    
    it 'should return true for a p element starting with text in square brackets' do 
      expect_section("<root><p>[ADDITIONAL FORCE BILL.] <member>Mr. Sheridan</member></p></root>", true)
    end
    
    it 'should return true for a p element with text in square brackets that is interrupted by a col tag' do 
      text = "<root><p><member>[PETITION FROM BERKS AGAINST AD-
      <col>26</col>
      DITIONAL FORCE BILL.] Mr. Charles Dundas</member> <membercontribution>presented to the house a petition</p></root>"
      expect_section(text, true)
    end
    
    it 'should return true for a section that has square bracketed text in the member tag' do 
      text = "<root><p><member>[Minutes.]</member> <membercontribution>The Sheriffs of </membercontribution></p></root>"
      expect_section(text, true)
    end
    
  end
  
  def run_preprocessor input_file
    @input_file = data_file_path(input_file)
    @output_file = @input_file+".clean"
    @preprocessor.clean_file(@input_file, overwrite=false)
    @output_xml = Hpricot.XML(File.open(@output_file))
  end
  
  describe "when asked to clean an input file with some sections" do 
  
    before do 
      run_preprocessor("preprocessing/debates_some_sections.xml")
    end
  
    it 'should move initial paragraphs into a section in the debates tag if there is more than one initial paragraph and create appropriate titles' do 
      @output_xml.at('houselords/p').should be_nil
      @output_xml.at('houselords/debates/section/title[text()*=MINUTES]').should_not be_nil
    end
    
    it 'should move an end paragraph into the end of the debates tag, giving it a section wrapper' do 
      last_section = @output_xml.at('houselords debates section:nth-last-child(0)')
      last_section.inner_html.should == "<title>TITLE</title><p id=\"end\">para at end</p>\n"
    end
    
    it 'should move a single initial paragraph into a section if it starts with "[MINUTES" and create a title for it' do 
      doc = ['<housecommons>', 
             '<date format="1805-03-13">Wednesday, March 13.</date>',
             '<title>HOUSE OF COMMONS</title>', 
             '<p>[MINUTES.]&#x2014;Colonel Barton, from the office of the Inspector General</p>',
             '<debates>',
             '<p>Stuff</p>',
             '</debates>',
             '</housecommons>'].join("\n")
      content = Hpricot.XML(doc)
      result = @preprocessor.move_paras_into_debates(content)
      result.at('housecommons/p').should be_nil
      result.at('housecommons/debates/section/title[text()*=MINUTES]').should_not be_nil
    end
    
  end
  
  describe "when grouping content into sections" do 

    before do 
      run_preprocessor("preprocessing/content_outside_sections.xml")
    end

    it 'should not alter the contents of column tags' do 
      @output_xml.at('//col[text()*=767]').should_not be_nil
    end
    
    it 'should delete empty column tags' do 
      @output_xml.at('//col[text()=]').should be_nil
    end
    
    it 'should delete empty appendix tags' do 
      @output_xml.at('//appendix[text()=]').should be_nil
    end

  end
  
  
  describe "when asked to clean an input file " do
    
    before do 
      run_preprocessor("preprocessing/debates_preprocessor_example.xml")
    end
    
    it 'should get an output file path' do 
      File.stub!(:new).and_return(mock(File, :null_object => true))
      @preprocessor.should_receive(:outfile).with(@input_file, overwrite=false)
      @preprocessor.clean_file(@input_file, overwrite=false)
    end
  
    it 'should produce an output file' do 
      File.exists?(@output_file).should be_true
    end 
    
    it 'should not disturb column tags in the file' do 
      @output_xml.at('//col[text()*=5]').should_not be_nil
    end    
    
    it 'should produce an output file with a debates tag inside a housecommons tag' do 
      @output_xml.at('housecommons/debates').should_not be_nil
    end
    
    it 'should produce an output file with a title tag inside the housecommons tag' do 
      @output_xml.at('housecommons/title').should_not be_nil
    end
    
    it 'should produce an output file with a date tag inside the housecommons tag' do 
      @output_xml.at('housecommons/date').should_not be_nil
    end
    
    it 'should produce an output file that does not have any p tags directly inside the housecommons tag' do 
      @output_xml.at('housecommons/p').should be_nil
    end
    
    it 'should not restructure a well-formed file' do 
      doc = ['<housecommons>', 
             '<date format="1805-03-13">Wednesday, March 13.</date>',
             '<title>HOUSE OF COMMONS</title>', 
             '<debates>',
             '<p>Stuff</p>',
             '</debates>',
             '</housecommons>'].join("\n")
      contents = Hpricot.XML(doc)
      expected = contents.to_s
      @preprocessor.create_debates_tag(contents).to_s.should == expected
    end
  
  end
  
  describe "when asked to clean a file with a top level paragraph in square brackets" do 

    before do 
      run_preprocessor("preprocessing/housecommons_speaker_in_chair.xml")
    end

    it 'should add a section to contain the paragraph named, titling it with the content in square brackets' do
      @output_xml.at('housecommons/p').should be_nil
      @output_xml.at('section/p').should_not be_nil
    end

  end
  
  describe "when asked to clean a westminsterhall file" do 

    before do 
      run_preprocessor("preprocessing/westminsterhall.xml")
    end

    it 'should move all orphan paragraphs into sections' do
      @output_xml.at('westminsterhall/p').should be_nil
      @output_xml.at('section/title[text()*=MR. EDWARD O\'HARA in the Chair]').should_not be_nil
    end

  end

  describe "when cleaning file with a top level speaker paragraph" do 

    before do 
      run_preprocessor("preprocessing/housecommons_speaker_indisposed.xml")
    end

    it 'should add a section to contain the paragraph named, titling it "Preamble"' do
      @output_xml.at('housecommons/p').should be_nil
      @output_xml.at('section/p').should_not be_nil
      @output_xml.at('section/title[text()*=Preamble]').should_not be_nil
    end
    
  end
  
  describe "when cleaning a file with a paragraph between sections" do 
    
    before do 
      run_preprocessor("preprocessing/debates_para_outside_section.xml")
    end
    
    it 'should move paragraph outside section in to preceding section if there is one and it has no title' do
      @output_xml.at('housecommons/p').should be_nil
      @output_xml.at('section/p[@id=S5LV0304P0-04721]').should_not be_nil
    end
    
  end
  
  describe 'when cleaning a file with writtenanswers between two debates sections' do 
  
    before do 
      run_preprocessor('preprocessing/writtenanswers_in_debates.xml')
    end
    
    it 'should not create two preamble sections' do
      @output_xml.search('housecommons/debates/section/title[text()*=Preamble]').size.should == 1 
    end
  
  end
  
  describe 'when cleaning a file where the title of the first section within the debates element is empty' do 
  
    before do 
      run_preprocessor('preprocessing/empty_first_section_title.xml')
    end
  
    it 'should set the title of the first section to "Preamble"' do 
      @output_xml.at('housecommons/debates/section/title[text()*=Preamble]').should_not be_nil
    end
  
  end
  
end