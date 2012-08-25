require File.dirname(__FILE__) + '/../spec_helper'

describe ExternalReferenceResolver do 

  describe 'when a StringScanner error is raised in any_references?' do 
  
    it 'should return false' do 
      resolver = ExternalReferenceResolver.new('')
      resolver.stub!(:screening_pattern).and_return('screen')
      resolver.stub!(:positive_patterns).and_return(['positive'])
      scanner = mock(StringScanner)
      resolver.stub!(:scanner).and_return(scanner)
      scanner.stub!(:exist?).with(resolver.screening_pattern).and_return(true)
      scanner.stub!(:exist?).with(resolver.positive_patterns.first).and_raise StringScanner::Error
      resolver.any_references?.should be_false
    end
    
  end
  
end