
class SiteMapEntry
  attr_accessor :location, :last_modification

  def initialize location, last_modification, hostname
    location = "http://#{hostname}/#{location}" unless location.starts_with?('http')
    @location, @last_modification = location, last_modification
  end
end

class SiteMap
  attr_reader :model, :empty, :site_maps
   
  def self.max_entries
    30000
  end
  
  def route_helper
    @@route_helper ||= RouteHelper.new nil, nil, @hostname
  end

  def initialize hostname, logger=nil
    @logger = logger
    @hostname = hostname
  end

  def url_for url_helper_method, id_hash
    route_helper.send url_helper_method, id_hash
  end
  
  # over ride in subclass
  def create_sitemap
  end

  def write_to_file!
    raise "can't write empty sitemap to file" if empty?
    raise "can only write to file once" if site_maps.empty?
    
    self.site_maps.each do |location, data| 
      Zlib::GzipWriter.open(location) do |file|
        @logger.write 'writing: ' + location + "\n" if @logger
        file.write data
      end
    end

    @site_maps = {}
  end

  def empty?
    empty
  end

  def populate_sitemap name, pages
    unless (@empty = pages.empty?)
      index = 1
      @site_maps = {}
      pages.each_slice(SiteMap.max_entries) do |page_group|
        site_map = [] <<
            %Q|<?xml version="1.0" encoding="UTF-8"?>\n| <<
            %Q|<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">\n|
        page_group.each do |page|
          site_map <<
              '<url><loc>' << page.location << "</loc>" <<
              '<lastmod>' << page.last_modification.to_s << "</lastmod></url>\n" if page.location
        end
        site_map <<
            %Q|</urlset>\n|
          
        @site_maps["public/sitemap_#{name}_#{index}.xml.gz"] = site_map.join('')
        index += 1
      end
    end
  end

  protected

    def new_entry location, last_modification=Date.today
      SiteMapEntry.new location, last_modification, @hostname
    end

end

class ModelSiteMap < SiteMap
  def create_sitemap
    populate_sitemap_for_model model, url_name
  end

  def url_name
    nil
  end
  
  def add_index_pages(resources, stem, pages)
    if !resources.empty? && resources.first.respond_to?(:slug)
      resources = resources.sort_by(&:slug)
      letters = resources.inject({}) {|hash,r| hash[r.slug[0..0]]=true; hash }
      ('a'..'z').each do |letter|
        pages << new_entry("#{stem}/#{letter}") if letters[letter]
      end
    end
  end

  def populate_sitemap_for_model model_class, url_helper_method=nil
    type = model_class.name.downcase
    url_helper_method = "#{type}_url".to_sym unless url_helper_method
    stem = type.pluralize
    pages = [new_entry(stem)]
    resources = model_class.find(:all)

    add_index_pages(resources, stem, pages)

    pages += resources.collect do |resource|
      url = url_for(url_helper_method, resource)
      new_entry(url)
    end

    populate_sitemap stem, pages
  end

end

class PersonSiteMap < ModelSiteMap
  def model
    Person
  end
  
  def create_sitemap

    pages = [new_entry('people')]
    people = Person.find_all_sorted
    add_index_pages(people, 'people', pages)
    people.each do |person|
      url = url_for(:person_url, person)
      pages << new_entry(url)
      person.active_years.each do |year|
        url = url_for(:person_year_url, {:name => person.slug, :year => year})
        pages << new_entry(url)
      end
    end

    populate_sitemap 'people', pages
  end

end

class OfficeSiteMap < ModelSiteMap
  def model
    Office
  end
end

class ConstituencySiteMap < ModelSiteMap
  def model
    Constituency
  end
end

class ActSiteMap < ModelSiteMap
  def model
    Act
  end
end

class BillSiteMap < ModelSiteMap
  def model
    Bill
  end
end

class VolumeSiteMap < SiteMap
  def create_sitemap
    entries = [new_entry('volumes')]
    
    Series.find(:all).each do |series|
      url = url_for(:series_index_url, series.id_hash)
      entries << new_entry(url)
    end

    Monarch.find_all.each do |monarch|
      url = url_for(:monarch_index_url, :monarch_name => monarch.slug)
      entries << new_entry(url)
    end

    Volume.find(:all).each do |volume|
      url = url_for(:volume_url, volume.id_hash)
      entries << new_entry(url)
    end

    populate_sitemap 'volumes', entries
    entries = nil
  end
end

class SittingSiteMap < SiteMap

  attr_reader :year, :sittings

  def self.make_sitting_sitemaps total_processes, process_index, hostname, logger
    sitemap_for_years total_processes, process_index do |year|
      sittings = Sitting.find_for_year(year)
      site_map = SittingSiteMap.new(year, sittings, hostname, logger)
      site_map.create_sitemap
      site_map.write_to_file! unless site_map.empty?
    end
  end
  
  def self.sitemap_for_years total_processes, process_index
    (FIRST_DATE.year..LAST_DATE.year).to_a.in_groups_of(total_processes) do |years|
      if years[process_index]
        yield years[process_index]
      end
    end
  end
  
  def initialize year, sittings, hostname, logger=nil
    @year = year
    @sittings = sittings
    @logger = logger
    @hostname = hostname
  end

  def decade_start_with_sittings?
    (year % 10 == 0)
  end

  def create_sitemap
    @entries = []
    @entries << new_entry("") if year == FIRST_DATE.year
    @entries << new_entry("sittings/#{year}s") if decade_start_with_sittings?
    @unique_locations = {}

    sittings.each do |sitting|
      sections = sitting.top_level_sections
      first_section_for_sitting = true
      sections.each do |section|
        handle_section section, first_section_for_sitting
        first_section_for_sitting = false
      end
      sitting = nil
    end
    
    @unique_locations = nil
    populate_sitemap year.to_s, @entries
    @entries = nil
  end

  protected
    def handle_section section, first_section_for_sitting=false
      id = section.id_hash

      if first_section_for_sitting
        location = "sittings/#{id[:year]}"
        @entries << new_entry(location) unless @unique_locations[location]
        @unique_locations[location] = true

        location = "sittings/#{id[:year]}/#{id[:month]}"
        @entries << new_entry(location) unless @unique_locations[location]
        @unique_locations[location] = true

        location = "sittings/#{id[:year]}/#{id[:month]}/#{id[:day]}"
        @entries << new_entry(location) unless @unique_locations[location]
        @unique_locations[location] = true
      end

      if section.linkable?
        location = "#{id[:type]}/#{id[:year]}/#{id[:month]}/#{id[:day]}/#{id[:id]}"
        @entries << new_entry(location)
      end

      section.sections.each {|s| handle_section s}
    end
end
