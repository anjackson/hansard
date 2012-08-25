require File.dirname(__FILE__) + '/../spec_helper'

describe WrittenStatementsSitting do

  before do
    @statements = WrittenStatementsSitting.new
  end

  describe 'when asked for top level sections' do
    it 'should return its groups' do
      groups = mock('groups')
      @statements.should_receive(:groups).and_return groups
      @statements.top_level_sections.should == groups
    end
  end

  describe 'when asked for each section' do
    describe 'and has a section' do
      it 'should yield the section' do
        section = mock('section')
        @statements.should_receive(:all_sections).and_return [section]
        @statements.each_section do |a_section|
          a_section.should == section
        end
      end
    end
  end
  
  describe ' when rendering sitting as xml' do 
  
    it 'should render a title tag containing the escaped title' do 
      written_statements_sitting = WrittenStatementsSitting.new(:title => 'Test & Title', 
                                                          :date => Date.new(1812,1,1))
      written_statements_sitting.to_xml.should have_tag('title', :text => 'Test &amp; Title')
    end
    
  end

end
