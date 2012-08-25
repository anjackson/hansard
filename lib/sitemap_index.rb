require File.dirname(__FILE__) + '/sitemap.rb'
require 'zlib'

SITE_MAPS = [VolumeSiteMap, PersonSiteMap, OfficeSiteMap, ConstituencySiteMap, ActSiteMap, BillSiteMap] unless defined? SITE_MAPS

class SiteMapIndex

  def initialize(hostname, logger=nil)
    @logger = logger
    @hostname = hostname
  end

  def write_to_file!
    site_maps = write_site_maps
    write_site_index
  end

  def clear_sitemaps
    Dir.glob(File.join(public_dir, 'sitemap_*')).each do |file|
      File.delete(file)
    end
  end
  
  private
  
    def public_dir
      "#{RAILS_ROOT}/public"
    end
    
    def write_site_maps
      write_maps_for_index_urls
    end

    def write_maps_for_index_urls
      SITE_MAPS.each do |site_map_type|
        site_map = site_map_type.new(@hostname, @logger)
        site_map.create_sitemap
        site_map.write_to_file!
        site_map = nil
      end
    end

    def write_site_index
      siteindex = [] <<
          %Q|<?xml version="1.0" encoding="UTF-8"?>\n| <<
          %Q|<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/siteindex.xsd">\n|
      site_maps = Dir.glob(File.join(public_dir, 'sitemap_*.gz'))
      site_maps.each do |site_map|
        siteindex <<
            "<sitemap>" <<
            "<loc>#{site_map.gsub(RAILS_ROOT + '/public', 'http://'+ @hostname )}</loc>" <<
            "<lastmod>#{File.stat(site_map).mtime.to_date}</lastmod>" <<
            "</sitemap>\n"
      end
      siteindex <<
          %Q|</sitemapindex>\n|

      File.open("public/sitemap_index.xml",'w') do |file|
        @logger.write 'writing: ' + file.path + "\n" if @logger
        file.write siteindex.join('')
      end
    end

end
