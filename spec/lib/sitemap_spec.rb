require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../lib/sitemap'

describe SiteMapEntry, 'when created' do
  
  it 'should set last modification' do
    entry = SiteMapEntry.new 'location', 'date', 'hostname'
    entry.last_modification.should == 'date'
  end
  
  it 'should set location by adding protocal and host' do
    entry = SiteMapEntry.new 'location', 'date', 'hostname'
    entry.location.should == "http://hostname/location"
  end
  
  it 'should leave location unaltered if it already has http protocol and host' do
    url = 'http://hansard.millbanksystems.com/location'
    entry = SiteMapEntry.new url, 'date', 'hostname'
    entry.location.should == url
  end

end

describe SiteMap do

  it 'should return empty? with value of empty attribute' do
    map = SiteMap.new 'hostname'
    map.stub!(:empty).and_return true
    map.empty?.should be_true
    map.stub!(:empty).and_return false
    map.empty?.should be_false
  end

  describe 'when populating sitemap xml text' do
    before do
      @map = SiteMap.new 'hostname'
    end
    
    describe 'when an empty array of pages is given' do
      it 'should set empty? to true' do
        @map.populate_sitemap 'name', []
        @map.empty?.should be_true
      end
    end

    describe 'when a non-empty array of pages is given' do
      before do
        @date = 'last_modification'
        @location = 'location'
        @entry = SiteMapEntry.new @location, @date, 'hostname'
        @name = 'name'
        @map.populate_sitemap @name, [@entry]
      end
      
      it 'should create a hash of file locations and data' do
        @map.site_maps.should == {"public/sitemap_name_1.xml.gz" => %Q|<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">
<url><loc>http://hostname/#{@location}</loc><lastmod>#{@date}</lastmod></url>
</urlset>\n|}
      end
    end

    describe 'when sitemap is for a model class' do
      it 'should create map based on model instance urls' do
        map = OfficeSiteMap.new 'hostname'

        resource = mock('resource', :slug => 'prime-minister')
        Office.stub!(:find).with(:all).and_return [resource]

        root_entry = mock('root entry')
        map.stub!(:new_entry).with("offices").and_return root_entry

        index_entry = mock('index entry')
        map.stub!(:new_entry).with("offices/p").and_return index_entry
        map.stub!(:url_for).with(:office_url, resource).and_return 'offices/prime-minister'

        resource_entry = mock('resource entry')
        map.stub!(:new_entry).with('offices/prime-minister').and_return resource_entry

        map.stub!(:populate_sitemap).with('offices', [root_entry, index_entry, resource_entry])
        map.create_sitemap
      end
    end
    
    describe 'when creating a sitemap for people urls' do
      
      before do 
        @map = PersonSiteMap.new 'hostname'
        @entry = mock('entry', :location => '', :last_modification => '')
        @map.stub!(:new_entry).and_return(@entry)
        @person = mock('resource', :slug => 'baroness', :active_years => [1933])
        Person.stub!(:find_all_sorted).and_return([@person])
        @map.stub!(:url_for).with(:person_url, @person).and_return 'people/baroness'
        @map.stub!(:url_for).with(:person_year_url, :name => @person.slug, :year => 1933).and_return('people/baroness/1933')
      end
      
      it 'should create a map entry for the root people URL' do
        @map.should_receive(:new_entry).with('people').and_return(@entry)
        @map.create_sitemap
      end
      
      it 'should create a map entry for every letter index url' do 
        @map.should_receive(:new_entry).with('people/b').and_return(@entry)
        @map.create_sitemap
      end
      
      it 'should create a map entry for every person url' do 
        @map.should_receive(:new_entry).with('people/baroness').and_return(@entry)
        @map.create_sitemap
      end
      
      it 'should populate the sitemap with its entries' do
        @map.stub!(:new_entry).and_return(@entry)
        @map.should_receive(:populate_sitemap).with('people', [@entry, @entry, @entry, @entry])
        @map.create_sitemap
      end
      
      it 'should create map entries for each of a person\'s active years' do 
        @map.should_receive(:new_entry).with('people/baroness/1933').and_return(@entry)
        @map.create_sitemap  
      end
      
    end
    
    describe 'when asked to make sitting sitemaps with a total number of processes and a process index' do
      
      before do
        File.stub!(:write)
      end
      
      it 'should ask for years to generate sitemaps for' do 
        SittingSiteMap.should_receive(:sitemap_for_years).with(1,0)
        SittingSiteMap.make_sitting_sitemaps(1,0, 'hostname', nil)
      end
      
      it 'should ask for the sittings for each year it gets back' do
        SittingSiteMap.stub!(:sitemap_for_years).and_yield(1990)
        Sitting.should_receive(:find_for_year).with(1990).and_return([])
        SittingSiteMap.make_sitting_sitemaps(1,0, 'hostname', nil)
      end
      
      it 'should create a sitting sitemap for each year' do 
        SittingSiteMap.stub!(:sitemap_for_years).and_yield(1990)
        Sitting.stub!(:find_for_year).with(1990).and_return([])
        sitemap = mock('sitting sitemap', :empty? => false)
        SittingSiteMap.stub!(:new).with(1990, [], 'hostname', nil).and_return(sitemap)
        sitemap.should_receive(:create_sitemap)
        sitemap.should_receive(:write_to_file!)
        SittingSiteMap.make_sitting_sitemaps(1,0, 'hostname', nil)
      end
       
    end

    describe 'when asked to yield years for generating sitemaps' do 
      
      it 'should yield every nth+m year from the first to the last year covered by the app where n is the total number of processes and m is the process id' do 
        years = []
        SittingSiteMap.sitemap_for_years(50, 0){ |year| years << year }
        years.should == [1803, 1853, 1903, 1953, 2003]
      end
    
    end
    
    describe 'when sitemap is for a year of section urls' do
      
      before do 
        year = 1900
        id_hash = {:type=>"lords", :day=>"25", :month=>"mar", :year=>1900, :id=>"postmarking-of-mail"}
        section = mock('section', :linkable? => true, :id_hash => id_hash, :sections=>[] )
        sections = [section]
        sitting = mock('sitting', :top_level_sections=> sections)
        @sittings = [sitting]
        @map = SittingSiteMap.new year, @sittings, 'hostname'
        @entry = mock('entry', :location => '', :last_modification => '')
        @map.stub!(:new_entry).and_return @entry
      end
      
      it 'should create an entry for the root url if the year is the first year the application covers' do 
        @map = SittingSiteMap.new FIRST_DATE.year, @sittings, 'hostname'
        @map.stub!(:new_entry).and_return @entry
        @map.should_receive(:new_entry).with('').and_return @entry
        @map.create_sitemap
      end
      
      it 'should create an entry for each decade url if the year is the first in the decade' do 
        @map.should_receive(:new_entry).with("sittings/1900s").and_return @entry
        @map.create_sitemap
      end
      
      it 'should not create an entry for the decade url if the year is not the first in the decade' do 
        @map = SittingSiteMap.new 1901, @sittings, 'hostname'
        @map.stub!(:new_entry).and_return @entry
        @map.should_not_receive(:new_entry).with("sittings/1900s").and_return @entry
        @map.create_sitemap
      end
 
      it 'should create an entry for each year url' do 
        @map.should_receive(:new_entry).with("sittings/1900").and_return @entry
        @map.create_sitemap
      end
      
      it 'should create an entry for each month url' do 
        @map.should_receive(:new_entry).with("sittings/1900/mar").and_return @entry
        @map.create_sitemap
      end
      
      it 'should create an entry for each day url' do 
        @map.should_receive(:new_entry).with("sittings/1900/mar/25").and_return @entry
        @map.create_sitemap
      end
      it 'should create an entry for each section url' do 
        @map.should_receive(:new_entry).with("lords/1900/mar/25/postmarking-of-mail").and_return @entry
        @map.create_sitemap
      end
      
      it 'should create a sitemap with the name being the year' do
        @map.should_receive(:populate_sitemap).with('1900', [@entry, @entry, @entry, @entry, @entry])
        @map.create_sitemap
      end
      
    end

    describe 'when sitemap is for Volumes urls' do
      
      before do 
        @map = VolumeSiteMap.new 'hostname'
        Monarch.stub!(:find_all).and_return([])
        @entry = mock('entry', :location => '', :last_modification => '')
        @map.stub!(:new_entry).and_return(@entry)
      end
      
      it 'should create an entry for the volumes index url' do 
        @map.should_receive(:new_entry).with('volumes').and_return @entry
        @map.create_sitemap
      end
      
      it 'should create an entry for each series index url' do 
        series = mock('series', :house=>'both', :id_hash=> {:series=>"1"})
        Series.stub!(:find).and_return [series]
        @map.should_receive(:new_entry).with("http://hostname/volumes/1").and_return @entry
        @map.create_sitemap
      end 
      
      it 'should create an entry for each monarch index url' do 
        monarch = mock('monarch', :slug=>'elizabeth-ii')
        Monarch.should_receive(:find_all).and_return [monarch]
        @map.should_receive(:new_entry).with("http://hostname/volumes/elizabeth-ii").and_return @entry
        @map.create_sitemap
      end
      
      it 'should create an entry for each volume url' do 
        volume = mock('volume', :id_hash=>{:volume_number=>300, :series=>"5L"})
        Volume.should_receive(:find).with(:all).and_return [volume]
        @map.should_receive(:new_entry).with("http://hostname/volumes/5L/300").and_return @entry
        @map.create_sitemap
      end
    
      it 'should populate the sitemap with its entries' do
        @map.should_receive(:populate_sitemap).with('volumes', [@entry])
        @map.create_sitemap
      end
    
    end
    
  end

  it 'should have a RouteHelper' do
    SiteMap.new('hostname').route_helper.should be_an_instance_of(RouteHelper)
  end

  describe 'when initializing in subclass' do
    it 'should set a model type' do
      [PersonSiteMap,OfficeSiteMap,ConstituencySiteMap,ActSiteMap,BillSiteMap].each do |type|
        map = type.new 'hostname'
        map.model.name.should == type.name.sub('SiteMap','')
      end
    end
  end

  describe 'when writing out sitemaps' do
    
    before do
      @map = SiteMap.new 'hostname'
      @map.stub!(:empty?).and_return false
      @sitemap_text = 'sitemap text'
      @map.stub!(:site_maps).and_return({ 'test_location' => @sitemap_text })
    end

    it 'should raise exception if there are no entries' do
      @map.stub!(:empty?).and_return true
      lambda { @map.write_to_file! }.should raise_error(Exception)
    end

    it 'should raise exception if the sitemaps have already been written' do
      @map.stub!(:site_maps).and_return {}
      lambda { @map.write_to_file! }.should raise_error(Exception)
    end

    it 'should write_to_zip each sitemap' do
      Zlib::GzipWriter.stub!(:open)
      file = mock('file')
      file.should_receive(:write).with(@sitemap_text).exactly(2).times
      Zlib::GzipWriter.should_receive(:open).with('location').and_yield file
      Zlib::GzipWriter.should_receive(:open).with('location 2').and_yield file
      @map.stub!(:site_maps).and_return({'location' => @sitemap_text, 
                                         'location 2' => @sitemap_text})

      @map.write_to_file!
    end
    
  end

end