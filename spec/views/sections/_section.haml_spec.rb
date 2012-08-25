require File.dirname(__FILE__) + '/../../spec_helper'

describe "_section partial", 'when formatting a section that contains subsections' do
  
  before do
    @sub_section = mock_model(Section, :is_written_body? => false)
    @india_section = mock_model(Section, :title => 'INDIA.',
                                         :slug => 'india', 
                                         :contributions => [], 
                                         :sections =>  [@sub_section])
    template.stub!(:section).and_return(@india_section)
    template.stub!(:render)
  end

  it 'should render sub-sections as links to sub-section pages' do   
    template.should_receive(:render).with(:partial => "partials/section_link", 
                                          :collection => @india_section.sections)
    render :partial => 'sections/section.haml', :object => @india_section
  end
  
  it 'should render sub-sections as sections if the first is a written body' do 
    @sub_section.stub!(:is_written_body?).and_return(true)
    template.should_receive(:render).with(:partial => "sections/section", 
                                          :collection => @india_section.sections)
    render :partial => 'sections/section.haml', :object => @india_section
  end
  
end
