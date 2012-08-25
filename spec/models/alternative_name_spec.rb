require File.dirname(__FILE__) + '/../spec_helper'


describe AlternativeName, ' when returning its name' do 

  it 'should return a name in the form "Lord Peter Wimsey"' do 
    alternative_name = AlternativeName.new(:firstname => 'Peter', 
                                           :lastname  => 'Wimsey', 
                                           :honorific => 'Lord')
    alternative_name.name.should == 'Lord Peter Wimsey'
  end

end
