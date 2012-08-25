require File.dirname(__FILE__) + '/../spec_helper'

describe Constituency, 'on creation' do

  it 'should populate slug from complete name' do
    Constituency.stub!(:find_by_slug).with('west-hampshire')
    constituency = Constituency.new
    constituency.stub!(:complete_name).and_return('West Hampshire')
    constituency.valid?
    constituency.slug.should == 'west-hampshire'
    constituency.id_hash.should == {:name=>'west-hampshire'}
  end

  it 'should add index to slug if it collides with another slug' do
    Constituency.stub!(:find_by_slug).with('west-hampshire').and_return(mock_model(Constituency))
    constituency = Constituency.new
    constituency.stub!(:complete_name).and_return('West Hampshire')
    constituency.valid?
    constituency.slug.should == 'west-hampshire-1'
    constituency.id_hash.should == {:name=>'west-hampshire-1'}
  end

end

describe Constituency, 'when asked to find by name and years' do 

  it 'should return an empty array if no name attribute is given' do 
    attributes = {}
    Constituency.find_by_name_and_years(attributes).should == []
  end
  
  it 'should return an empty array if no start date or end date attribute is given' do 
    attributes = {:name => 'test constituency'}
    Constituency.find_by_name_and_years(attributes).should == []
  end
  
  it 'should ask for all constituencies with the name and whose start year and end year are within a year of those of the start and end date given if both are supplied' do 
    attributes = { :name => 'test constituency', 
                   :start_date => Date.new(1918, 1, 3),
                   :end_date => Date.new(1922, 12, 31) }
    Constituency.should_receive(:find).with(:all, :conditions => ['name = ? and start_year >= ? and start_year <= ?
                                                                   and end_year >= ? and end_year <= ?'.squeeze(' '), 
                                                  attributes[:name], 1917, 1919, 1921, 1923])
    Constituency.find_by_name_and_years(attributes)    
  end
  
  it 'should ask for all constituencies with the name and whose start year is within a year if not given and end date' do 
    attributes = { :name => 'test constituency', 
                   :start_date => Date.new(1918, 1, 3) }
    Constituency.should_receive(:find).with(:all, :conditions => ['name = ? and start_year >= ? and start_year <= ?', 
                                                  attributes[:name], 1917, 1919])
    Constituency.find_by_name_and_years(attributes)
  end

  it 'should ask for all constituencies with the name and whose end year is within a year either way if not given and end date' do 
    attributes = { :name => 'test constituency', 
                   :end_date => Date.new(1922, 12, 31) }
    Constituency.should_receive(:find).with(:all, :conditions => ['name = ? and end_year >= ? and end_year <= ?', 
                                                  attributes[:name], 1921, 1923])
    Constituency.find_by_name_and_years(attributes)
  end
end


describe Constituency, 'when asked if it is a match to a name' do
  
  it 'should not return true if the match form of the name is not the same as the match form of the constituency and there are no aliases' do 
    Constituency.stub!(:match_form).with('name one').and_return('no match')
    Constituency.stub!(:match_form).with('name two').and_return('name')
    constituency = Constituency.new(:name => 'name one')
    constituency.match?('name two').should be_false
  end
  
  it 'should return true if the match_form of the name is the same as the match form of the name of the constituency' do 
    Constituency.stub!(:match_form).with('name one').and_return('name')
    Constituency.stub!(:match_form).with('name two').and_return('name')
    constituency = Constituency.new(:name => 'name one')
    constituency.match?('name two').should be_true
  end
  
  it 'should return true if the match form of any of it\'s aliases is the same as the match form of the name' do 
    Constituency.stub!(:match_form).with('no match').and_return('no match')
    Constituency.stub!(:match_form).with('name two').and_return('name')
    constituency = Constituency.new(:name => 'no match')
    constituency_alias = ConstituencyAlias.new(:alias => 'name two')
    constituency.constituency_aliases << constituency_alias
    constituency.match?('name two').should be_true
  end
  
end

describe Constituency, 'when asked for the match form of a name' do 
 
  it 'should return "bristol north west" for "Bristol, North-West"' do 
    Constituency.match_form("Bristol, North-West").should == "bristol north west"
  end

  it 'should return "cambridgeshire east south" for "South-East Cambridgeshire"' do 
    Constituency.match_form("South-East Cambridgeshire").should == "cambridgeshire east south"
  end

end

describe Constituency, "when returning it's complete name" do

  before do
    @constituency = Constituency.new(:name => 'Cork')
  end

  it 'should return "Cork" for name "Cork"' do
    @constituency.complete_name.should == 'Cork'
  end

  it 'should return "Cork (county)" for name "Cork" and area type "county"' do
    @constituency.area_type = 'county'
    @constituency.complete_name.should == 'Cork (county)'
  end

  it 'should return "Cork (county) (Ireland)" for name "Cork" and area type "county" and region "Ireland"' do
    @constituency.region = 'Ireland'
    @constituency.area_type = 'county'
    @constituency.complete_name.should == 'Cork (county) (Ireland)'
  end

end

describe Constituency, "when returning years" do

  before do
    @constituency = Constituency.new
  end

  it 'should return an empty string if there is no start year' do
    @constituency.years.should == ''
  end

  it 'should return "1992-1993" for a start year of 1992 and end year of 1993' do
    @constituency.start_year = 1992
    @constituency.end_year = 1993
    @constituency.years.should == '1992-1993'
  end

  it 'should return "1992-" for a start year of 1992 and no end year' do
    @constituency.start_year = 1992
    @constituency.years.should == '1992-'
  end

end

describe Constituency, "when finding constituencies by name and date" do

  before do
    @name = "test constituency"
    @date = Date.new(2003, 1, 2)
    @year = @date.year
    @constituency = mock_model(Constituency)
    @conditions = ["name = ? and start_year <= ? and (end_year >= ? or end_year is null)", @name, @year, @year]
  end

  it 'should return nil if no constituency is found' do
    Constituency.stub!(:find).with(:all, :conditions => @conditions).and_return([])
    Constituency.find_by_name_and_date(@name, @date).should be_nil
  end

  it 'should return nil if more than one constituency is found' do
    Constituency.stub!(:find).with(:all, :conditions => @conditions).and_return([@constituency, @constituency])
    Constituency.find_by_name_and_date(@name, @date).should be_nil
  end

  it 'should generate several versions of the constituency name passed' do
    Constituency.stub!(:find).with(:all, :conditions => @conditions).and_return([@constituency])
    Constituency.should_receive(:generate_versions).with('test, constituency').and_return(["test constituency"])
    Constituency.find_by_name_and_date("test, constituency", @date)
  end

  it 'should return a constituency with the name passed and a start and end year that span the date passed' do
    Constituency.stub!(:find).with(:all, :conditions => @conditions).and_return([@constituency])
    Constituency.find_by_name_and_date(@name, @date).should == @constituency
  end

  it 'should return a constituency that has one of the name variants as an alias' do
    Constituency.stub!(:find_by_alias).with(@name, @date).and_return([@constituency])
    Constituency.find_by_name_and_date(@name, @date).should == @constituency
  end

  it 'should not look for constituencies if the corrected name is nil' do
    Constituency.stub!(:corrected_name).with('test, constituency')
    Constituency.should_not_receive(:find)
    Constituency.find_by_name_and_date("test, constituency", @date)
  end

end

describe Constituency, "when generating different name versions" do

  it 'should generate a corrected, normalized, general punctuation-stripped and apostrophe-stripped version' do
    Constituency.should_receive(:corrected_name).and_return('name')
    Constituency.should_receive(:normalized_name).and_return('name')
    Constituency.should_receive(:stripped_name).and_return('name')
    Constituency.should_receive(:name_without_apostrophes).and_return('name')
    Constituency.send(:generate_versions, 'name')
  end

  it 'should return an empty list if the corrected name is nil' do
    Constituency.stub!(:corrected_name)
    Constituency.send(:generate_versions, 'name').should == []
  end

end

describe Constituency, 'when asked for missing dates' do

  it 'should return a list including any period longer than a year within the duration of the constituency where it has no representative' do
    constituency = Constituency.new(:start_year => 1834,
                                    :end_year   => 1867)
    membership = mock_model(CommonsMembership, :first_possible_date => Date.new(1834, 1, 1),
                                               :last_possible_date => Date.new(1864, 1, 1))
    constituency.stub!(:commons_memberships).and_return([membership])
    constituency.missing_dates.should == [[Date.new(1864, 1, 1), Date.new(1867, 1, 1)]]
  end

  it 'should return a list not including any period less than a year within the duration of the constituency where it has no representative' do
    constituency = Constituency.new(:start_year => 1834,
                                    :end_year   => 1867)
    membership = mock_model(CommonsMembership, :first_possible_date => Date.new(1834, 1, 1),
                                               :last_possible_date => Date.new(1866, 1, 1))
    constituency.stub!(:commons_memberships).and_return([membership])
    constituency.missing_dates.should == []
  end

end

describe Constituency, "when correcting constituency names" do

  def should_correct_name name, corrected_name
    Constituency.corrected_name(name).should == corrected_name
  end

  it 'should correct " Ashfield" to "Ashfield"' do
    should_correct_name ' Ashfield', 'Ashfield'
  end

  it 'should correct "Knutsford " to "Knutsford"' do
    should_correct_name 'Knutsford  ', 'Knutsford'
  end

  it 'should correct "Berwick-upon- Tweed" to "Berwick-upon-Tweed"' do
    should_correct_name 'Berwick-upon- Tweed', 'Berwick-upon-Tweed'
  end

  it 'should correct "Second Church Estates Commissioner, representing the Church <image src="S6CV0239P0I0317"></image><col>613</col>Commissioners" to "Second Church Estates Commissioner, representing the Church Commissioners"'do
    should_correct_name 'Second Church Estates Commissioner, representing the Church <image src="S6CV0239P0I0317"></image><col>613</col>Commissioners', nil
  end

  it 'should correct "Caernarfon:" to "Caernarfon"' do
    should_correct_name "Caernarfon:", "Caernarfon"
  end

  it 'should correct "Caernarfon," to "Caernarfon"' do
    should_correct_name "Caernarfon,", "Caernarfon"
  end

  it 'should correct "Fermanagh and Co. Tyrone" to "Fermanagh and Co Tyrone"' do
    should_correct_name "Fermanagh and Co. Tyrone", "Fermanagh and Co Tyrone"
  end

  it 'should correct "Holborn and St. Pancras" to "Holborn and St Pancras"' do
    should_correct_name "Holborn and St. Pancras", "Holborn and St Pancras"
  end

  it 'should correct "Holborn amd St. Pancras" to "Holborn and St Pancras"' do
    should_correct_name "Holborn amd St. Pancras", "Holborn and St Pancras"
  end

  it 'should correct "Gloucestershire. South" to "Gloucestershire South"' do
    should_correct_name "Gloucestershire. South", "Gloucestershire South"
  end

  it 'should correct "Greenock and. Port Glasgow" to "Greenock and Port Glasgow"' do
    should_correct_name "Greenock and. Port Glasgow", "Greenock and Port Glasgow"
  end

  it 'should correct "Boston arid Skegness" to "Boston and Skegness"' do
    should_correct_name "Boston arid Skegness", "Boston and Skegness"
  end

  it 'should correct "Cities of London an Westminster" to "Cities of London and Westminster"' do
    should_correct_name "Cities of London an Westminster", 'Cities of London and Westminster'
  end

  it 'should correct "Dagenham:" to "Dagenham"' do
    should_correct_name "Dagenham:", "Dagenham"
  end

  it 'should not correct "West Ham"' do
    should_correct_name 'West Ham', 'West Ham'
  end

  it 'should correct "Dr. Kim Howells" to nil' do
    should_correct_name "Dr. Kim Howells", nil
  end

  it 'should correct "Mr. Tony McNulty" to nil' do
    should_correct_name "Mr. Tony McNulty", nil
  end

  it 'should correct "Mrs. Sylvia Heal" to nil' do
    should_correct_name "Mrs. Sylvia Heal", nil
  end

  it 'should correct "Ms Patricia Hewitt" to nil' do
    should_correct_name "Ms Patricia Hewitt", nil
  end

  it 'should correct "Sir Myer Galpern" to nil' do
    should_correct_name "Sir Myer Galpern", nil
  end

  it 'should correct "The Leader of the House of Commons" to nil' do
    should_correct_name "The Leader of the House of Commons", nil
  end

  it 'should correct "The Minister for Trade and Investment" to nil' do
    should_correct_name "The Minister for Trade and Investment", nil
  end

  it 'should correct "The Parliamentary Under-Secretary of State for Foreign and Commonwealth Affairs" to nil' do
    should_correct_name "The Parliamentary Under-Secretary of State for Foreign and Commonwealth Affairs", nil
  end

  it 'should correct "The Parliamentary Under-Secretary of State for Transport (Mr. David Jamieson" to nil' do
    should_correct_name "The Parliamentary Under-Secretary of State for Transport (Mr. David Jamieson", nil
  end

  it 'should correct "on behalf of the House of Commons Commission" to nil' do
    should_correct_name "on behalf of the House of Commons Commission", nil
  end

  it 'should correct "representing the House of Commons Commission" to nil' do
    should_correct_name "representing the House of Commons Commission", nil
  end

  it 'should correct "Chairman of the Administration Committee" to nil' do
    should_correct_name "Chairman of the Administration Committee", nil
  end

  it 'should correct "Lords Commissioner to the Treasury" to nil' do
    should_correct_name "Lords Commissioner to the Treasury", nil
  end

  it 'should correct "Vice-Chamberlain of Her Majesty\'s Household" to nil' do
    should_correct_name "Vice-Chamberlain of Her Majesty's Household", nil
  end

  it 'should correct "Bexhill &amp; Battle" to "Bexhill and Battle"' do
    should_correct_name "Bexhill &amp; Battle", "Bexhill and Battle"
  end

  it 'should correct "Ruislip&#x2013; Northwood" to "Ruislip-Northwood"' do
    should_correct_name "Ruislip&#x2013; Northwood", "Ruislip-Northwood"
  end

  it 'should not correct "The Wrekin"' do
    should_correct_name "The Wrekin", "The Wrekin"
  end

end


describe Constituency, " when correcting and normalizing constituency names" do

  def should_normalize_name name, normalized_name
    corrected_name = Constituency.corrected_name(name)
    Constituency.normalized_name(corrected_name).should == normalized_name
  end

  it 'should correct and normalize "Flint, East," to "Flint East"' do
    should_normalize_name "Flint, East,", "Flint East"
  end

  it 'should correct and normalize "Mid-Worcestershire" to "Worcestershire Mid"' do
    should_normalize_name "Mid-Worcestershire", "Worcestershire Mid"
  end

  it 'should correct and normalize "North-East Derbyshire;" to "Derbyshire North East"' do
    should_normalize_name "North-East Derbyshire;", "Derbyshire North East"
  end

  it 'should correct and normalize "East Worthing and Shoreham" to "Worthing East and Shoreham"' do
    should_normalize_name "East Worthing and Shoreham", "Worthing East and Shoreham"
  end

  it 'should correct and normalize "Stoke-on-Trent, South" to "Stoke-on-Trent South"' do
    should_normalize_name "Stoke-on-Trent, South", "Stoke-on-Trent South"
  end

  it 'should correct and normalize "Faversham and Mid-Kent" to "Faversham and Kent Mid"' do
    should_normalize_name "Faversham and Mid-Kent", "Faversham and Kent Mid"
  end

  it 'should correct and normalize "The Wrekin" to "Wrekin, The"' do
    should_normalize_name "The Wrekin", "Wrekin, The"
  end

  it 'should correct and normalize "Ross, Skye and Inverness, West" to "Ross, Skye and Inverness West"' do
    should_normalize_name "Ross, Skye and Inverness, West", "Ross, Skye and Inverness West"
  end

  it 'should correct and normalize "Aberdeen, E" to "Aberdeen East"' do
    should_normalize_name "Aberdeen, E", "Aberdeen East"
  end

  it 'should correct and normalize "Aberdeen, E." to "Aberdeen East"' do
    should_normalize_name "Aberdeen, E.", "Aberdeen East"
  end

  it 'should correct and normalize "Armagh N." to "Armagh North"' do
    should_normalize_name "Armagh N.", "Armagh North"
  end

  it 'should correct and normalize "Bethnal Green, N.E." to "Bethnal Green North East"' do
    should_normalize_name "Bethnal Green, N.E.", "Bethnal Green North East"
  end

  it 'should correct and normalize "Bethnal Green, N.W." to "Bethnal Green North West"' do
    should_normalize_name "Bethnal Green, N.W.", "Bethnal Green North West"
  end

  it 'should correct and normalize "Lanark, N. E." to "Lanark North East"' do
    should_normalize_name "Lanark, N. E.", "Lanark North East"
  end

  it 'should correct and normalize "West Ham, North" to "West Ham North"' do
    should_normalize_name "West Ham, North", "West Ham North"
  end

  it 'should correct and normalize "West Bromwich, East" to "West Bromwich East"' do
    should_normalize_name "West Bromwich, East", "West Bromwich East"
  end

  it 'should correct and normalize "West Ham, N." to "West Ham North"' do
    should_normalize_name "West Ham, N.", 'West Ham North'
  end
end

describe Constituency, " when correcting, normalizing and stripping constituency names" do

  def should_strip_name name, stripped_name
    corrected_name = Constituency.corrected_name(name)
    normalized_name = Constituency.normalized_name(corrected_name)
    Constituency.stripped_name(normalized_name).should == stripped_name
  end

  it 'should strip "Ruislip-Northwood" to "Ruislip Northwood"' do
    should_strip_name "Ruislip-Northwood", "Ruislip Northwood"
  end

  it 'should strip "City of Durham" to "Durham"' do
    should_strip_name "City of Durham", "Durham"
  end

  it 'should strip "Lewisham, Deptford" to "Lewisham Deptford"' do
    should_strip_name "Lewisham, Deptford", "Lewisham Deptford"
  end

  it 'should strip "Ealing, Acton and Shepherd\'s Bush" to "Ealing Acton and Shepherd\'s Bush"' do
    should_strip_name "Ealing, Acton and Shepherd\'s Bush", "Ealing Acton and Shepherd's Bush"
  end

end

describe Constituency, "generally" do
  
  it 'should return "/public/constituency-histories/west-hampshire.doc" when generating a history_doc path for a constituency with a name of "West Hampshire"' do
    Constituency.stub!(:find_by_slug).with('west-hampshire')
    constituency = Constituency.new
    constituency.stub!(:complete_name).and_return('West Hampshire')
    constituency.valid?
    constituency.history_doc.should == RAILS_ROOT + '/public/constituency-histories/west-hampshire.doc'
  end

end
