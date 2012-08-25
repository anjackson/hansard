require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::LordsParser do

  def paragraph_element html
    Hpricot(html).at('p')
  end

  describe 'when handling member contribution containing house divided text' do
    it 'should handle division text at end of member contribution' do
      html = %Q|<p id="S5LV0040P0-02854"><member>THE EARL of MIDLETON</member><membercontribution>: We all<lb/>
        On Question, whether subsection (1) shall stand part of the clause&#x2014;<lb/>
        Their Lordships divided: Contents, 31; Not-Contents, 11.</membercontribution></p>|
      parser = Hansard::LordsParser.new ''
      parser.stub!(:anchor_id)
      section = mock_model(Section)
      section.stub!(:add_contribution)
      contribution = mock_model(ProceduralContribution)

      parser.should_receive(:create_house_divided_contribution).with('Their Lordships divided: Contents, 31; Not-Contents, 11.').and_return contribution
      parser.should_receive(:add_division_after_divided_text).with(section, contribution)
      member_contribution = parser.handle_member_contribution paragraph_element(html), section
      member_contribution.text.should == %Q|: We all<lb/>
        On Question, whether subsection (1) shall stand part of the clause&#x2014;|
    end
  end

  describe 'when unexpected paragraph is in debates element' do
    
    before do
      @parser = Hansard::LordsParser.new ''
    end
    
    it 'should raise an exception' do
      node = mock('paragraph', :name => 'p', :inner_text => 'random text', :elem? => true)
      sitting = mock('sitting', :debates_sections_count => 0)
      lambda { @parser.handle_child_element node, sitting }.should raise_error(Exception, /unexpected paragraph/)
    end
  end

  describe 'when unexpected element is in debates element' do
    it 'should raise an exception' do
      parser = Hansard::LordsParser.new ''
      sitting = mock('sitting')
      node = mock('element', :name => 'ob', :elem? => true)
      lambda { parser.handle_child_element node, sitting }.should raise_error(Exception, /unexpected element/)
    end
  end

  describe 'when parsing a lords source file' do
    before(:all) do
      Contribution.stub!(:acts_as_solr)
      @sitting_type = HouseOfLordsSitting
      @sitting_date = Date.new(1909, 9, 20)
      @sitting_date_text = 'Monday, 20th September, 1909.'
      @sitting_title = 'HOUSE OF LORDS.'
      @sitting_start_column = '1'
      @sitting_end_column = '2'
      @volume = mock_model(Volume)
      source_file = mock_model(SourceFile, :volume => @volume)
      file = 'houselords_example.xml'
      @sitting = parse_hansard_file Hansard::LordsParser, data_file_path(file), nil, source_file
    end

    it 'should create a sitting with association to the volume' do
      @sitting.volume.should == @volume
    end

    it 'should create a section for section element in debates' do
      @sitting.debates.sections[0].should_not be_nil
      @sitting.debates.sections[0].should be_an_instance_of(Section)
    end

    it 'should set title on section correctly' do
      @sitting.debates.sections[0].title.should == 'PREVENTION AND TREATMENT OF BLINDNESS (SCOTLAND) BILL.'
    end

    it 'should create procedural contribution for paragraph element' do
      @sitting.debates.sections[0].contributions[0].should be_an_instance_of(ProceduralContribution)
      @sitting.debates.sections[0].contributions[0].xml_id.should == 'S5LV0003P0-00084'
      @sitting.debates.sections[0].contributions[0].text.should == 'The following Bills received the Royal Assent&#x2014;'
    end

    it_should_behave_like "All sittings"
  end

end
