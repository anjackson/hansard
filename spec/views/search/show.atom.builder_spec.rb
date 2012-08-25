require File.dirname(__FILE__) + '/../../spec_helper'

describe 'search/show.atom.builder', '' do 

  before do 
    @search = mock_model(Search, :null_object => true, :query => 'test', :highlight_prefix => nil, :highlight_suffix => nil)
    @paginator = mock('paginator', :null_object => true, :current_page => 1, :total_pages => 5)
    assigns[:search] = @search
    assigns[:paginator] = @paginator
    template.stub!(:url_for)
  end
  
  def do_render
    render 'search/show.atom.builder'
  end

  it 'should have a feed tag with lang US, and xmlns attributes for openSearch and atom' do 
    do_render
    feed_tag = '<feed xml:lang="en-US" xmlns:openSearch="http://a9.com/-/spec/opensearch/1.1/" xmlns="http://www.w3.org/2005/Atom">'
    response.body.should match(/#{feed_tag}/)
  end
  
  it 'should have a feed title tag' do 
    do_render
    response.should have_tag('feed title')
  end

  it 'should have an openSearch:totalResults tag showing the total number of results' do 
    @paginator.stub!(:total_entries).and_return(12)
    @paginator.stub!(:per_page).and_return(10)
    total_results_tag = '<openSearch:totalResults>12</openSearch:totalResults>'
    do_render
    response.body.should match(/#{total_results_tag}/)
  end
  
  it 'should have an openSearch:startIndex tag showing the index of the first result being returned' do 
    @paginator.stub!(:offset).and_return(4)
     start_index_tag = '<openSearch:startIndex>5</openSearch:startIndex>'
     do_render
     response.body.should match(/#{start_index_tag}/)
  end
  
  it 'should have an openSearch:itemsPerPage tag showing the number of items per page' do 
    @paginator.stub!(:per_page).and_return(50)
     per_page_tag = '<openSearch:itemsPerPage>50</openSearch:itemsPerPage>'
     do_render
     response.body.should match(/#{per_page_tag}/)
  end

  it 'should have an openSearch:Query tag with the searchTerms attribute populated' do 
    @search.stub!(:query).and_return('test')
    @paginator.stub!(:current_page).and_return(1)
    do_render
    response.body.should match(/<openSearch:Query/)
    response.should have_tag('[searchTerms=test][startPage=1][role=request]')
  end

  it 'should have an alternate link tag pointing to the html version of the results page' do 
    do_render
    response.should have_tag('link[type=text/html][href=http://test.host][rel=alternate]')
  end
  
  it 'should have a self link pointing to the page itself' do 
    do_render
    response.should have_tag('link[type=application/atom+xml][href=http://test.host/][rel=self]')
  end
  
  it 'should have a first link pointing to the first page of results' do 
    template.stub!(:first_results_url).and_return('http://test.host')
    do_render
    response.should have_tag('link[type=application/atom+xml][href=http://test.host][rel=first]')
  end
  
  it 'should have a last link pointing to the last page of results' do 
    template.stub!(:last_results_url).and_return('http://test.host')
    do_render
    response.should have_tag('link[type=application/atom+xml][href=http://test.host][rel=last]')
  end
  
  it 'should not have a previous link if this is the first page of results' do 
    @paginator.stub!(:current_page).and_return(1)
    do_render
    response.should_not have_tag('link[type=application/atom+xml][rel=previous]')
  end
  
  it 'should have a previous link pointing to the previous page of results if this is not the first page' do 
    @paginator.stub!(:current_page).and_return(2)
    template.stub!(:previous_results_url).and_return('http://test.host')
    do_render
    response.should have_tag('link[type=application/atom+xml][href=http://test.host][rel=previous]')
  end
  
  it 'should not have a next link if this is the last page of results' do 
    @paginator.stub!(:current_page).and_return(5)
    do_render
    response.should_not have_tag('link[type=application/atom+xml][rel=next]')
  end
  
  it 'should have a next link pointing to the next page of results if this is not the last page' do 
    @paginator.stub!(:current_page).and_return(4)
    template.stub!(:next_results_url).and_return('http://test.host')
    do_render
    response.should have_tag('link[type=application/atom+xml][href=http://test.host][rel=next]')
  end
  
  it 'should have a search link pointing to /search.xml' do 
    do_render
    response.should have_tag('link[rel=search][type=application/opensearchdescription+xml][href=http://test.host/search.xml]')
  end
  
  describe 'when showing entries' do

    before do 
      template.stub!(:section_contribution_url).and_return('http://test.host')
      mock_result = mock_model(Contribution, 
                               :null_object => true, 
                               :title_via_associations => 'test title',
                               :date => Date.new(1902, 1, 1))
      results = []
      3.times { results << mock_result }
      @search.stub!(:get_results).and_return(results)
    end
    
    it 'should have an entry tag for each result' do
      do_render
      response.should have_tag('entry', :count => 3)
    end
    
    it 'should have an alternate link pointing to the section contribution url for each entry' do 
      do_render
      response.should have_tag('entry link[type=text/html][href=http://test.host][rel=alternate]', :count => 3)
    end
    
    it 'should have a title tag with type html showing the result title via associations for each entry' do 
      do_render
      response.should have_tag('entry title[type=html]', :text => 'test title', :count => 3)
    end
    
    it 'should have a content tag with type html showing the hit fragment for the result for each entry' do 
      template.stub!(:hit_fragment).and_return('test fragment')
      do_render
      response.should have_tag('entry content[type=html]', :text => 'test fragment', :count => 3)
    end
    
    it 'should have an author tag saying "Millbank Systems" for each element' do 
      do_render
      response.should have_tag('entry author', :text => 'Millbank Systems', :count => 3)
    end
    
    it 'should have an updated tag showing the current date and time for each entry' do 
      time_now = Time.now
      Time.stub!(:now).and_return(time_now)
      do_render
      response.should have_tag('entry updated', :text => time_now.xmlschema, :count => 3)
    end
    
    it 'should have a published tag showing the date of the contribution' do 
      do_render
      response.should have_tag('entry published', :text => Date.new(1902, 1, 1).xmlschema, :count => 3)
    end
  
  end
  
end