require File.dirname(__FILE__) + '/../../spec_helper'

describe 'the application layout', 'generally' do
  
  before do 
    template.stub!(:render).with(:partial => "partials/front_page")
  end

  def have_javascript text
    have_tag "script[type=text/javascript]", :text => /#{text}/
  end
  
  def render_layout
    render 'layouts/application.haml'
  end

  it 'should render the HTML 5 doctype of "<!doctype html>"' do
    render_layout
    response.body.should match(/\A<!doctype html>/)
  end

  it 'should have the lang type of "en-GB" on the html element' do 
    render_layout
    response.should have_tag('html[lang=en-GB]')
  end
  
  it 'should have a body element with a id of "hansard-millbanksytems-com"' do 
    render_layout
    response.should have_tag('body[id=hansard-millbanksytems-com]')
  end
  
  it 'should have a body element with a class which is not blank' do 
    render_layout
    response.should_not have_tag('body[class=""]')
  end

  it "should write day navigation content to the page if @day is true" do 
    assigns[:day] = true
    @controller.template.should_receive(:day_navigation)
    render_layout
  end
  
  it 'should include an autodiscovery link for the Atom version of the current page if @search is defined' do 
    assigns[:search] = mock_model(Search)
    @controller.template.stub!(:atom_url).and_return('http://test.host.atom')
    render_layout
    response.should have_tag('link[href=http://test.host.atom][rel=alternate][title=Atom][type=application/atom+xml]')
  end
  
  it 'should not include an Atom autodiscovery link if @search is not defined' do 
    render_layout
    response.should_not have_tag('link[rel=alternate][title=Atom][type=application/atom+xml]')
  end
  
  it 'should include the google-analytics javascript if in production' do 
    @controller.template.stub!(:is_production_env?).and_return true
    render_layout
    response.should have_javascript('google-analytics')
  end
  
  it 'should include the trackPageview javascript if in production' do 
    @controller.template.stub!(:is_production_env?).and_return true
    render_layout
    response.should have_javascript('trackPageview')
  end
  
  it 'should not include the google-analytics javascript if not in production' do 
    @controller.template.stub!(:is_production_env?).and_return false
    render_layout
    response.should_not have_javascript('google-analytics')
  end
  
  it 'should not include the trackPageview javascript if not in production' do 
    @controller.template.stub!(:is_production_env?).and_return false
    render_layout
    response.should_not have_javascript('trackPageview')
  end
  
end