require File.dirname(__FILE__) + '/../spec_helper'

describe UrlResolver, 'when recognizing a URL' do

  def should_match_url text, references
    references = [references] if references.is_a? String
    resolver = UrlResolver.new(text)
    resolver.references.size.should == references.size
    resolver.references.should == references
  end
  
  it 'should match "http://www.fhfb.gov"' do
    text = 'Federal Housing Finance Board and Council of Mortgage Lenders websites (http://www.fhfb.gov)'
    should_match_url text, 'http://www.fhfb.gov'
  end
  
  it 'should match "http:&#x002F;&#x002F;www.fhfb.gov"' do
    text = 'Federal Housing Finance Board and Council of Mortgage Lenders websites (http:&#x002F;&#x002F;www.fhfb.gov)'
    should_match_url text, 'http:&#x002F;&#x002F;www.fhfb.gov'
  end
  
  it 'should replace "&#x002F" with "/" in the link generated' do
    text = 'http:&#x002F;&#x002F;www.fhfb.gov'
    UrlResolver.new('').reference_replacement(text).should have_tag('a[href=http://www.fhfb.gov]')
  end
  
  it 'should exclude adjacent tags like "http://www.cabinet-office.gov.uk/regulation/rrap/index.asp.</p>"' do
    text = '<p>The small business friendly measures are highlighted in the Regulators Reform Action Plan which is available from the Libraries of the House or online at http://www.cabinet-office.gov.uk/regulation/rrap/index.asp</p>'
    should_match_url text, 'http://www.cabinet-office.gov.uk/regulation/rrap/index.asp'
  end
  
  it 'should match "http:// www.crimestatistics.org.uk"' do 
    text = 'http:// www.crimestatistics.org.uk'
    should_match_url text, "http:// www.crimestatistics.org.uk"
  end
  
  it 'should match "(http://www.iue.it/RSCAS)" but exclude the brackets' do 
    text = "(http://www.iue.it/RSCAS)"
    should_match_url text, "http://www.iue.it/RSCAS"
  end
  
  it 'should remove any spaces in the url to produce the href attribute for the link' do
    text = "http://www.ir.gov.uk/ria/eusd- ria.pdf"
    UrlResolver.new('').reference_replacement(text).should have_tag('a[href=http://www.ir.gov.uk/ria/eusd-ria.pdf]')
  end
  
  it 'should match "http://www.defra.gov. uk/animalh/by-prods/default.htm"' do 
    text = "http://www.defra.gov. uk/animalh/by-prods/default.htm"
    should_match_url text, "http://www.defra.gov. uk/animalh/by-prods/default.htm"
  end

  it 'should match "http://untreaty.un.org/ENGLISH/bible/englishinternetbible/partI/chapterXVIII/ treaty10.asp"' do 
    text = "http://untreaty.un.org/ENGLISH/bible/englishinternetbible/partI/chapterXVIII/ treaty10.asp."
    should_match_url text, "http://untreaty.un.org/ENGLISH/bible/englishinternetbible/partI/chapterXVIII/ treaty10.asp"
  end
  
  it 'should match "http:/www.dwp.gov.uk/publications/dwp/2002/health-safety/eli-review/index.htm"' do 
    text = "http:/www.dwp.gov.uk/publications/dwp/2002/health-safety/eli-review/index.htm"
    should_match_url text, "http:/www.dwp.gov.uk/publications/dwp/2002/health-safety/eli-review/index.htm"
  end
  
  it 'should match "http://www.doh.gov.uk/cin/cin2001 latables.htm"' do 
    text = "http://www.doh.gov.uk/cin/cin2001 latables.htm"
    should_match_url text, "http://www.doh.gov.uk/cin/cin2001 latables.htm"
  end
  
  it 'should match "http://www.nationalstatistics.gov.uk/downloads/ theme_health/hsq22_vl.pdf"' do 
    text = "http://www.nationalstatistics.gov.uk/downloads/ theme_health/hsq22_vl.pdf"
    should_match_url text, "http://www.nationalstatistics.gov.uk/downloads/ theme_health/hsq22_vl.pdf"
  end
  
  it 'should match "http ://www.womenandequalityunit. gov.uk"' do 
    text = "http ://www.womenandequalityunit. gov.uk"
    should_match_url text, "http ://www.womenandequalityunit. gov.uk"
  end
  
  it 'should match "http://www.statistics.gov.uk/downloads/ theme_other/Regional_Government_Accounts.pdf"' do 
    text = "http://www.statistics.gov.uk/downloads/ theme_other/Regional_Government_Accounts.pdf"
    should_match_url text, "http://www.statistics.gov.uk/downloads/ theme_other/Regional_Government_Accounts.pdf"
  end
  
  it 'should match "http://www2.defra.gov. uk/research/project_data/Default.asp"' do 
    text = "http://www2.defra.gov. uk/research/project_data/Default.asp"
    should_match_url text, "http://www2.defra.gov. uk/research/project_data/Default.asp"
  end
  
  it 'should match "www.probation.homeoffice.gov.uk"' do 
    text = "www.probation.homeoffice.gov.uk"
    should_match_url text, "www.probation.homeoffice.gov.uk"
  end
  
  it 'should match "www.bicester-centre.co.uk"' do 
    text = "www.bicester-centre.co.uk"
    should_match_url text, "www.bicester-centre.co.uk"
  end
  
  it 'should match "www.doh.gov.uk/public/psstaff.htm"' do 
    text = 'www.doh.gov.uk/public/psstaff.htm'
    should_match_url text, 'www.doh.gov.uk/public/psstaff.htm'
  end
  
  it 'should match "(www.Defra.gov.uk)"' do 
    text = "(www.Defra.gov.uk)"
    should_match_url text, "www.Defra.gov.uk"
  end
  
  it 'should add an "http" prefix to links that don\'t have one' do 
    text = "www.Defra.gov.uk"
    UrlResolver.new('').reference_replacement(text).should have_tag('a[href=http://www.Defra.gov.uk]')
  end
  
  it 'should match "http:// www.defra.gov.uk/animalh/by-prods/default.htm.," without the trailing punctuation' do 
    text = "http:// www.defra.gov.uk/animalh/by-prods/default.htm.,"
    should_match_url text, "http:// www.defra.gov.uk/animalh/by-prods/default.htm"
  end
  
  it 'should match "www.cabinet-Office.gov.uk/regulation/riaguidance/" without the trailing punctuation' do 
    text = "www.cabinet-Office.gov.uk/regulation/riaguidance/"
    should_match_url text, "www.cabinet-Office.gov.uk/regulation/riaguidance/"
  end
  
  it 'should match "http://www.cabinet-Office.gov.uk/regulation/riaguidance/" without the trailing punctuation' do 
    text = "http://www.cabinet-Office.gov.uk/regulation/riaguidance/"
    should_match_url text, "http://www.cabinet-Office.gov.uk/regulation/riaguidance/"
  end
  
  it 'should match "www.acbar.org" without the next word' do 
    text = "These are available on www.acbar.org. ACBAR plays a valuable role in Afghanistan"
    should_match_url text, "www.acbar.org"
  end
  
  
  it 'should match "http://www.dft gov.uk/stellent/ groups/dft_transstats/documents/ sectionhomepage/dft_transstats_page.hcsp"' do 
    text = "http://www.dft gov.uk/stellent/ groups/dft_transstats/documents/ sectionhomepage/dft_transstats_page.hcsp"
    should_match_url text, "http://www.dft gov.uk/stellent/ groups/dft_transstats/documents/ sectionhomepage/dft_transstats_page.hcsp"
  end
  
  it 'should match "http://www.homeoffice.gov uk/rds/immigration1.html"' do 
    text = "http://www.homeoffice.gov uk/rds/immigration1.html"
    should_match_url text, "http://www.homeoffice.gov uk/rds/immigration1.html"
  end

  
  it 'should match "http://www. statistics. gov. uk/methods_quality/ns_sec/downloads/SOC2000_Vol1_V5.pdf"' do 
      text = "http://www. statistics. gov. uk/methods_quality/ns_sec/downloads/SOC2000_Vol1_V5.pdf"
      should_match_url text, "http://www. statistics. gov. uk/methods_quality/ns_sec/downloads/SOC2000_Vol1_V5.pdf"
  end
  
  it 'should match "ttp://www.homeoffice.gov.uk/ rds/immigration1. html"' do 
    text = "ttp://www.homeoffice.gov.uk/ rds/immigration1. html"
    should_match_url text, "ttp://www.homeoffice.gov.uk/ rds/immigration1. html"
  end
  
  it 'should match "ttp://www.homeoffice.gov.uk/rds/immigration1. html"' do 
    text = "ttp://www.homeoffice.gov.uk/rds/immigration1. html"
    should_match_url text, "ttp://www.homeoffice.gov.uk/rds/immigration1. html"
  end
  
  it 'should match "www.discover northernireland.com"' do 
      text = "www.discover northernireland.com"
      should_match_url text, "www.discover northernireland.com"
  end

  it 'should match "http://www.local-transport dft.gov.uk/travelplans/mforum/index.htm"' do 
      text = "http://www.local-transport.dft gov.uk/travelplans/mforum/index.htm"
      should_match_url text, "http://www.local-transport.dft gov.uk/travelplans/mforum/index.htm"
  end
  
  it 'should match "http://www local-transport.dft.gov.uk/travelplans/mforum/index.htm"' do 
      text = "http://www local-transport.dft.gov.uk/travelplans/mforum/index.htm"
      should_match_url text, "http://www local-transport.dft.gov.uk/travelplans/mforum/index.htm"
  end
  
  it 'should not match a double quoted url' do 
    text = '"http://www.probation.homeoffice.gov.uk'
    should_match_url text, []
  end
  
  it 'should not match a single quoted url' do 
    text = "'http://www.probation.homeoffice.gov.uk"
    should_match_url text, []
  end

  it 'should match "at:http://www.housing.odpm.gov.uk/information/hma/index.htm"' do 
    text = "at:http://www.housing.odpm.gov.uk/information/hma/index.htm."
    should_match_url text, "http://www.housing.odpm.gov.uk/information/hma/index.htm"
  end
  
  it 'should match "www.dwp.gov.uk/asd/asd5/rports2003&#x2013;2004/rrep205.asp"' do 
    text = "www.dwp.gov.uk/asd/asd5/rports2003&#x2013;2004/rrep205.asp"
    should_match_url text, "www.dwp.gov.uk/asd/asd5/rports2003&#x2013;2004/rrep205.asp"
  end
  
  it 'should match "http://www.dfes.gov.uk/rsgatewav/DB/VOL/v000443/index. shtml"' do 
    text = "http://www.dfes.gov.uk/rsgatewav/DB/VOL/v000443/index. shtml"
    should_match_url text, "http://www.dfes.gov.uk/rsgatewav/DB/VOL/v000443/index. shtml"
  end
  
end
