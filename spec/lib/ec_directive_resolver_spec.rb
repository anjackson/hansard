require File.dirname(__FILE__) + '/../spec_helper'

describe EcDirectiveResolver, 'when recognizing a reference' do

  def should_match_reference text, references
    references = [references] if references.is_a? String
    resolver = EcDirectiveResolver.new(text)
    resolver.references.size.should == references.size
    resolver.references.should == references
  end

  it 'should find reference for text digits/digits/EEC' do
    text = '20/82 20 August 1982—EC Directive relating to the Quality of Water intended for Human Consumption (80/778/EEC).'
    should_match_reference text, '80/778/EEC'
  end

  it 'should find reference for text digits/digits/EC' do
    text = '20/82 20 August 1982—EC Directive relating to the Quality of Water intended for Human Consumption (80/778/EC).'
    should_match_reference text, '80/778/EC'
  end

  it 'should match on "EC .. directive (digits/digits)"' do
    text = 'No application has been made by the Thames water authority for a derogation from the maximum nitrate concentration in drinking water set by the EC drinking water directive (80/778).'
    should_match_reference text, '80/778'
  end

  it 'should match on "EC .. directive digits/digits"' do
    text = 'To ask the Secretary of State for the Environment if he will list those mineral waters produced in the United Kingdom that have been, or are to be, prohibited for public consumption under the EC drinking water directive 80/778; and if he will make a statement.'
    should_match_reference text, '80/778'
  end

  it 'should match on "EC directive digits/digits"' do
    text = 'The Government have granted these derogations under article 9(1)(a) of EC directive 80/778 because in the relevant cases there is no public health hazard, and the other terms of the directive are satisfied.'
    should_match_reference text, '80/778'
  end
  
  it 'should match  on "European Community directive (digits/digits)"' do
    text = 'Mr. Chris Smith asked the Secretary of State for the Environment why, under article 20 of the European Community directive (80/778) relating to the quality of water intended for human consumption, he has applied for a delay on lead for four years and on all private water supplies for 10 years for the United Kingdom as a whole, rather than specified geographical areas thereof.'
    should_match_reference text, '80/778'
  end

  it 'should match on "European Community directive No. digits/digits"' do
    text = 'To ask the Lord President of the Council (1) if he will take steps to ensure that the mineral waters sold by the Refreshment Department are fully British owned, fully meet the requirements of the Natural Mineral Water Regulation 1985 and conform to European Community directive No. 80/778; and if he will make a statement;'
    should_match_reference text, '80/778'
  end

  it 'should match on "EC directive No. 80/778;"' do
    text = '2) what information he has as to which of the natural mineral waters it is proposed to sell in the House do not meet the requirements of EC directive No. 80/778; and if he will make a statement.'
    should_match_reference text, '80/778'
  end

  it 'should match once on "European Community directive (digits/digits/EC)"' do
    text = 'Mr. Chris Smith asked the Secretary of State for the Environment why, under article 20 of the European Community directive (80/778/EC) relating to the quality of water intended for human consumption, he has applied for a delay on lead for four years and on all private water supplies for 10 years for the United Kingdom as a whole, rather than specified geographical areas thereof.'
    should_match_reference text, '80/778/EC'
  end

  it 'should match once on "European Community directive digits/digits/EC"' do
    text = 'Mr. Chris Smith asked the Secretary of State for the Environment why, under article 20 of the European Community directive 80/778/EC relating to the quality of water intended for human consumption, he has applied for a delay on lead for four years and on all private water supplies for 10 years for the United Kingdom as a whole, rather than specified geographical areas thereof.'
    should_match_reference text, '80/778/EC'
  end

  it 'should match all occurrences of digits/digits/EC' do
    text = 'Chapter 2 of Part 3 of the Energy Bill will implement Directives 2003/54/EC and 2003/55/EC and we shall be notifying the commission when the relevant clauses come into force.'
    should_match_reference text, ['2003/54/EC', '2003/55/EC']
  end
  
  it 'should match all occurrences of the format "EC Directive 98/44"' do
    text = 'Mr. Chris Smith asked the Secretary of State for the Environment why, under article 20 of the EC Directive 98/44 and article 19 of the EC Directive 98/43 relating to the quality of water intended for human consumption, he has applied for a delay on lead for four years and on all private water supplies for 10 years for the United Kingdom as a whole, rather than specified geographical areas thereof.'
    should_match_reference text, ['98/44', '98/43']
  end
  
  it 'should match "Directive 98/79/EC"' do 
    text = "Mr. Chris Smith asked the Secretary of State about Directive 98/79/EC and so on."
    should_match_reference text, ['98/79/EC']
  end

  it 'should match all occurrences of "Directive 2001/18"' do 
    text = 'Mr. Chris Smith asked the Secretary of State for the Environment why, under article 20 of the Directive 2001/18 and article 19 of the Directive 2001/20 relating to the quality of water intended for human consumption, he has applied for a delay on lead for four years and on all private water supplies for 10 years for the United Kingdom as a whole, rather than specified geographical areas thereof.'
    should_match_reference text, ['2001/18', '2001/20']
  end


end
