require File.dirname(__FILE__) + '/../spec_helper'

describe Acts::Slugged, "a slugged class when normalizing text" do 
  
  before do
    self.class.send(:include, Acts::Slugged)
    self.class.acts_as_slugged
  end
  
  it 'should normalize the text "Ö" to "o"' do 
    normalize_text("Ö").should == 'o'
  end
  
  it 'should normalize the text "GAS UNDERTAKING&#x25BF; PROFITS" to "gas-undertaking-profits"' do
    normalize_text("GAS UNDERTAKING&#x25BF; PROFITS").should == "gas-undertaking-profits"
  end
  
end