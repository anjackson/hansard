require File.dirname(__FILE__) + '/../spec_helper'

describe "index.haml for a sitting type", :shared => true do

  before do
    @date = Date.new(1959, 12, 31)
    assigns[:date] = @date
    assigns[:resolution] = :decade
    assigns[:sitting_type] = Sitting
    Sitting.stub!(:counts_in_interval).and_return({Date.new(1951,1,1) => 1})
    assigns[:timeline_resolution] = :year
  end

  def do_render
    render 'sittings/index.haml'
  end

  it 'should render a timeline for the period' do
    @controller.template.stub!(:timeline_options).and_return({})
    @controller.template.should_receive(:timeline).with(@date, :year, {:top_label=>"Sittings by decade"})
    do_render
  end
  
  it 'should contain individual elements with the text "1950", "1951", "1952", "1953", "1954", "1955", "1956", "1957", "1958" and "1959" if a URL of "/sittings/1950s" is given' do 
    do_render
    1950.upto(1959) { |year| response.body.should have_tag('td', :text => /#{year}/) }
  end
  
  it 'should contain a link with the text "1940s" with the target "/sittings/1940s" and a "rel" attribute with the value "prev" if a URL of "/sittings/1950s" is given' do 
    do_render
    response.should have_tag("a[href=/sittings/1940s][rel=prev nofollow]", :text => "1940s")
  end
  
  it 'should contain a link with the text "1960s" with the target "/sittings/1960s" and a "rel" attribute with the value "next" if a URL of "/sittings/1950s" is given' do 
    do_render
    response.should have_tag("a[href=/sittings/1960s][rel=next nofollow]", :text => "1960s")
  end

end