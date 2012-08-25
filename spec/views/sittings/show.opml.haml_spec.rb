require File.dirname(__FILE__) + '/../../spec_helper'

describe "sittings show.opml.haml", " in general" do

  before do 
    section = mock_model(Section, :linkable? => true, 
                                  :word_count => 5,
                                  :title => '', 
                                  :contributions => [],
                                  :id_hash => {},
                                  :sections => [])
    assigns[:sittings] = [mock_model(Sitting, :top_level_sections => [section])]
    assigns[:sitting_type] = Sitting
    assigns[:date] = Date.new(2003, 11, 30)
    @controller.template.stub!(:section_url).and_return('')
    do_render
  end
  
  def do_render 
    render "sittings/show.opml.haml"
  end

  it 'should have one root "opml" element with a version attribute of "2.0"' do 
    response.should have_tag('opml[version=2.0]', :count => 1)
  end

  it 'should have one "dateCreated" element with the text of a date expressed in RFC 822 format, within the "head" element' do 
    response.should have_tag('dateCreated', :text => "Sun, 30 Nov 2003 00:00:00 +0000", :count => 1)
  end

  it 'should have one "head" element within the root "opml" element' do 
    response.should have_tag('opml head', :count => 1)
  end
  
  it 'should have one "title" element within the "head" element' do 
    response.should have_tag('head title', :count => 1)
  end

  it 'should have one "ownerName" element with the text "UK Parliament", within the "head" element' do 
    response.should have_tag('head ownerName', :text => "UK Parliament", :count => 1)
  end

  it 'should have one "ownerEmail" element with the text "mail@robertbrook.com", within the "head" element' do 
    response.should have_tag('head ownerEmail', :text => "mail@robertbrook.com", :count => 1)
  end
  
  it 'should have one "ownerId" element with the text "http://www.parliament.uk", within the "head" element' do
    response.should have_tag('head ownerId', :text => "http://www.parliament.uk", :count => 1)
  end
  
  it 'should have one "docs" element with the text "http://www.opml.org/spec2", within the "head" element' do 
    response.should have_tag('head docs', :text => "http://www.opml.org/spec2", :count => 1)
  end
  
  it 'should have one "body" element within the root "opml" element' do 
    response.should have_tag('opml body', :count => 1)
  end
  
  it 'should have at least one "outline" element within the "body" element' do 
    response.should have_tag('body outline')
  end

end