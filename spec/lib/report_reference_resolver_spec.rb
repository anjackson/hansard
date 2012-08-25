require File.dirname(__FILE__) + '/../spec_helper'

describe ReportReferenceResolver, 'generally' do
  
  it "should return a date when getting a date from a type and date which is not a short date" do 
    reference_resolver = ReportReferenceResolver.new('')
    reference_resolver.get_date('17th November, 1938:').should == Date.new(1938, 11, 17)
  end
  
end

describe ReportReferenceResolver, ' when matching report references' do

  def should_match_report_reference text, reference_list
    resolver = ReportReferenceResolver.new(text)
    reference_list = [reference_list] if reference_list.is_a? String
    resolver.references.size.should == reference_list.size
    resolver.references.should == reference_list
  end
  
  def expect_match text
    should_match_report_reference(text, [text])
  end
  
  def should_match_params reference, params
    resolver = ReportReferenceResolver.new(reference)
    resolver.reference_params(reference).should == params
  end
  
  def should_extract text, params
    expect_match text
    should_match_params text, params
  end

  it 'should match the report reference "OFFICIAL REPORT, 4th July, 1938; col. 26, Vol. 338."' do 
    expected_params = { :date => Date.new(1938, 7, 4), 
                        :column => '26' }
    should_extract("OFFICIAL REPORT, 4th July, 1938; col. 26, Vol. 338.", expected_params)
  end
  
  it 'should match "OFFICIAL REPORT. 5th October, 1938 Vol. 339, c. 366."' do 
    expected_params = { :date => Date.new(1938, 10, 5), 
                        :column => '366' }
    should_extract("OFFICIAL REPORT. 5th October, 1938 Vol. 339, c. 366.", expected_params)
  end
  
  it 'should match "OFFICIAL REPORT, 17th November, 1938: Vol. 341, c. 1129."' do 
    expected_params = { :date => Date.new(1938, 11, 17), 
                        :column => '1129' }
    should_extract("OFFICIAL REPORT, 17th November, 1938: Vol. 341, c. 1129.", expected_params)
  end
  
  it 'should match "OFFICIAL REPORT. 31st October, 1966; Vol. 735, c. 5"' do
    expected_params = { :date => Date.new(1966, 10, 31),
                        :column => '5' }
    should_extract("OFFICIAL REPORT. 31st October, 1966; Vol. 735, c. 5", expected_params)
  end
  
  it 'should match "Official Report, House of Lords, 23rd September 1975; Vol. 364, c. 185."' do 
    expected_params = { :date => Date.new(1975, 9, 23),
                        :column => '185', 
                        :house => 'lords' }
    should_extract("Official Report, House of Lords, 23rd September 1975; Vol. 364, c. 185.", expected_params)
  end
  
  it 'should match "Official Report, 3rd May 1977; Vol. 931, c. 210–11."' do 
    expected_params = { :date => Date.new(1977, 5, 3),
                        :column => '210' }
    should_extract("Official Report, 3rd May 1977; Vol. 931, c. 210–11.", expected_params)
  end
  
  it 'should match "OFFICIAL REPORT, 23rd March, 1965; Written Answers, cols. 65–66."' do 
    expected_params = { :date => Date.new(1965, 3, 23),
                        :column => '65', 
                        :written_answer => true }
    should_extract("OFFICIAL REPORT, 23rd March, 1965; Written Answers cols. 65–66.", expected_params)
  end
  
  it 'should match "Official Report, 23rd May 1977; Vol. 932, 345"' do 
    expected_params = { :date => Date.new(1977, 5, 23),
                        :column => '345' }
    should_extract("Official Report, 23rd May 1977; Vol. 932, 345", expected_params)
  end
  
  it 'should match "OFFICIAL REPORT, 11th April, 1967; Vol. 744, c. 1011.23."' do
    expected_params = { :date => Date.new(1967, 4, 11), 
                        :column => '1011' }
    should_extract("OFFICIAL REPORT, 11th April, 1967; Vol. 744, c. 1011.23.", expected_params)
  end
  
  it 'should match "OFFICIAL REPORT, 20th April, 1967; Vol. 745, c. <span class="italic">153</span>"' do 
    expected_params = { :date => Date.new(1967, 4, 20),
                        :column => '153' }
    should_extract('OFFICIAL REPORT, 20th April, 1967; Vol. 745, c. <span class="italic">153</span>', expected_params)
  end
  
  it 'should match "OFFICIAL REPORT, 20th April, 1967; Vol. 745, c. 796&#x2013;7"' do 
    expected_params = { :date => Date.new(1967, 4, 20), 
                        :column => '796' }
    should_extract("OFFICIAL REPORT, 20th April, 1967; Vol. 745, c. 796&#x2013;7", expected_params)
  end
  
  it 'should match "OFFICIAL REPORT, 1St March. 1967; c. 455, vol. 742."' do
    expected_params = { :date => Date.new(1967, 3, 1), 
                        :column => "455" }
    should_extract("OFFICIAL REPORT, 1St March. 1967; c. 455, vol. 742.", expected_params) 
  end
  
  it 'should match "Official Report, Written Answers, 14th January 1992, col. 546"' do 
    expected_params = { :date => Date.new(1992, 1, 14), 
                        :column => "546", 
                        :written_answer => true }
    should_extract("Official Report, Written Answers, 14th January 1992, col. 546", expected_params)
  end
  
  it 'should match "OFFICIAL REPORT, 16th March, 1909, cols. 950, 952, 959."' do 
    expected_params = { :date => Date.new(1909, 3, 16), 
                        :column => "950" }
    should_extract("OFFICIAL REPORT, 16th March, 1909, cols. 950, 952, 959.", expected_params)
  end
  
  it 'should match "OFFICIAL REPORT, 8th April, 1967; Vol 744, c. 468."' do 
    expected_params = { :date => Date.new(1967, 4, 8), 
                        :column => "468" }
    should_extract("OFFICIAL REPORT, 8th April, 1967; Vol 744, c. 468.", expected_params)
  end
  
  it 'should match ""Official Report (Commons W.A.); 21/3/77, col. 409"' do 
    expected_params = { :date => Date.new(1977, 3, 21), 
                        :column => "409", 
                          :house => "commons", 
                          :written_answer => true }
    should_extract("Official Report (Commons W.A.); 21/3/77, col. 409", expected_params)
  end
      
  it 'should match "<span class="italic">Official Report</span>, Commons, WA, 4/2/80; col. 2."' do 
    expected_params = { :date => Date.new(1980, 2, 4), 
                        :column => "2", 
                        :house => 'commons', 
                        :written_answer => true }
    should_extract('<span class="italic">Official Report</span>, Commons, WA, 4/2/80; col. 2.', expected_params)
  end
  
  it 'should match "Official Report (Commons W.A.); 21/3/77, col. 409"' do 
    expected_params = { :date => Date.new(1977, 3, 21), 
                        :column => "409", 
                        :house => 'commons', 
                        :written_answer => true }
    should_extract("Official Report (Commons W.A.); 21/3/77, col. 409", expected_params)
  end
  
  it 'should match "Official Report, Commons, WA, 4/2/80; col. 2."' do 
    expected_params = { :date => Date.new(1980,2, 4), 
                        :column => "2", 
                        :house => 'commons', 
                        :written_answer => true }
    should_extract("Official Report, Commons, WA, 4/2/80; col. 2.", expected_params)
  end
  
  it 'should match "Official Report, House of Commons, 30th April 1985; col. WA 71"' do 
    expected_params = { :date => Date.new(1985, 4, 30), 
                        :column => "71", 
                        :house => 'commons', 
                        :written_answer => true }
    should_extract("Official Report, House of Commons, 30th April 1985; col. WA 71", expected_params)
  end
  
  it 'should match "3 March 2003,Official Report, column 72WS"' do   
    expected_params = { :date => Date.new(2003, 3, 3), 
                        :column => "72", 
                        :written_statement => true }
    should_extract("3 March 2003,Official Report, column 72WS", expected_params)
  end
  
  it 'should match "9th January 1996. (Official Report, col. WA 17)"' do 
    expected_params = { :date => Date.new(1996, 1, 9), 
                        :column => "17", 
                        :written_answer => true }
    should_extract("9th January 1996. (Official Report, col. WA 17)", expected_params)
  end
  
  it 'should match "3 March 2003,<span class="italic">Official Report,</span> column 71WS"' do 
    expected_params = { :date => Date.new(2003, 3, 3), 
                        :column => "71", 
                        :written_statement => true }
    should_extract('3 March 2003,<span class="italic">Official Report,</span> column 71WS', expected_params)
  end
 
  it 'should match "Official Report, 26th November, Written Answers, col. 270"' do 
    expected_params = { :month => 11, 
                        :day => 26, 
                        :written_answer => true, 
                        :column => "270"}
    should_extract('Official Report, 26th November, Written Answers, col. 270', expected_params)                  
  end
  
  it 'should match "18 June (Official Report, WA 120)"' do 
    expected_params = { :month => 6, 
                        :day => 18,
                        :written_answer => true, 
                        :column => '120' }
    should_extract("18 June (Official Report, WA 120)", expected_params)
  end
  
  it 'should match "9 February (Official Report, col. WA 138)"' do 
    expected_params = { :month => 2, 
                        :day => 9, 
                        :written_answer => true, 
                        :column => "138" }
    should_extract('9 February (Official Report, col. WA 138)', expected_params)
  end
  
  it 'should not match "1984 to 1986 in <span class="italic">Official Report,</i> 13"' do 
    should_match_report_reference('1986 in <span class="italic">Official Report,</span> 13', [])
  end

  it 'should extract empty params from "<span class="italic">Official Report,</span> 29 February 1986; Vol. 92, c. 506." (not a leap year)' do 
    expected_params = {}
    should_extract('<span class="italic">Official Report,</span> 29 February 1986; Vol. 92, c. 506.', expected_params)
  end

  it 'should match "8 May 2002, Official Report, column 179W"' do 
    expected_params = { :date => Date.new(2002, 5, 8),
                        :written_answer => true, 
                        :column => "179" }
    should_extract("8 May 2002, Official Report, column 179W", expected_params)
  end
    
end