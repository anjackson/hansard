require File.dirname(__FILE__) + '/../spec_helper'

describe 'An activerecord model', 'when serialized to json' do 

  it 'should recurse its include options for associated records of the same base type' do 
    sub_sub_section = Section.new
    sub_section = Section.new(:sections => [sub_sub_section])
    section = Section.new(:sections => [sub_section])
    json_string = section.to_json(:include => {:sections => {}})
    attribute_hash = ActiveSupport::JSON.decode(json_string)
    attribute_hash['section']['sections'].first['sections'].first.should_not be_empty
  end
  
end