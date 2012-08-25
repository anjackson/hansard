require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../lib/sitemap_index'

describe SiteMapIndex do
  
  before do 
    File.stub!(:delete)
  end
  
  it "should write a sitemap for index urls" do
    SITE_MAPS.each do |map_type|
      location = mock(SiteMapEntry)
      map = mock(map_type, :entry => location)
      map_type.should_receive(:new).and_return map
      map.should_receive(:create_sitemap)
      map.should_receive(:write_to_file!)
    end
    site_map_index = SiteMapIndex.new 'hostname'
    site_map_index.write_to_file!
  end

  it "should write the site index" do
    site_map_index = SiteMapIndex.new 'hostname'
    site_map_index.should_receive(:write_site_index)
    site_map_index.write_to_file!
  end

  it "should write a sitemap index to public/sitemap_index.xml containing each file in the sitemaps directory" do
    Dir.stub!(:glob).and_return(["#{RAILS_ROOT}/public/sitemaps/file"])
    File.stub!(:stat).and_return(mock('sitemap file', :mtime => Date.new(2008, 1, 3)))
    file = mock('file', :path=>'path')
    file.should_receive(:write).with(%Q[<?xml version="1.0" encoding="UTF-8"?>
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/siteindex.xsd">
<sitemap><loc>http://hostname/sitemaps/file</loc><lastmod>2008-01-03</lastmod></sitemap>
</sitemapindex>
])

    File.stub!(:open).with("public/sitemap_index.xml",'w').and_yield file
    site_map_index = SiteMapIndex.new 'hostname'
    site_map_index.write_to_file!
  end

end