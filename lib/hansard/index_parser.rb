require 'rubygems'
require 'open-uri'
require 'hpricot'

module Hansard
  class IndexParser

    def initialize file, logger=nil
      @logger = logger
      @doc = Hpricot.XML open(file)
    end

    def log text
      @logger.add_log text if @logger
    end
    
    def parse
      type = @doc.children[0].name
      if type == 'index'
        create_index
      else
        raise 'cannot create index, unrecognized type: ' + type
      end
    end

    private
  
    def create_index
      @image =  @doc.at('index/image').attributes['src']
      title = handle_node_text(@doc.at('index/title'))
      date_span = handle_node_text(@doc.at('index/p:nth(2)'))
      date_span.gsub!(/<\/?i>/, '')
      start_date_text, end_date_text = date_span.split(/&#x2013;|&#x2014;/)
      end_date = Date.parse(end_date_text)
      begin
        start_date = Date.parse(start_date_text)
        raise "bad date" if start_date.year == Time.now.year 
      rescue
        start_date = Date.parse(start_date_text + " #{end_date.year}")
      end
      @index = Index.new(:title => title, 
                         :start_date_text => start_date_text,
                         :end_date_text   => end_date_text, 
                         :start_date      => start_date, 
                         :end_date        => end_date)
    
      (@doc/'indexdiv').each do |indexdiv|
        handle_index indexdiv
      end
      @index
    end
    
    def handle_index element
      element.children.each do |child|
        if child.elem?
          name = child.name
          if name == 'index-letter'
            handle_index_letter(child)
          elsif (name == 'col' or name == 'image')
            handle_image_or_column(name, child)
          elsif name == 'p'
            handle_index_entry(child)
          else
            puts 'unexpected element in indexdiv: ' + name + ': ' + node.to_s
          end
        end
      end
    end
    
    def handle_index_letter element
      @index_letter = handle_node_text(element)
    end
    
    def handle_index_context element
      @index_context = handle_node_text(element)
    end
    
    def handle_index_entry element
      element.children.each do |child|
        if child.elem?
          name = child.name
          if name == 'b'
            handle_top_level_index_entry(child.children.first)
          elsif name == 'i'
            handle_index_context(child)
          # else
            # puts 'unexpected element in index entry: ' + name + ': ' + child.to_s
          end
        else
          handle_second_level_index_entry(child)  
        end
      end
    end
    
    def handle_top_level_index_entry element
      @index_context = nil
      @top_entry = IndexEntry.new(:text          => clean_text(element),
                                  :entry_context => @index_context,
                                  :letter        => @index_letter)
      # print "TOP LEVEL: #{clean_text(element)}\n"
      @index.index_entries << @top_entry
    end
    
    def handle_second_level_index_entry element 
      entry = IndexEntry.new(:text          => clean_text(element),
                             :entry_context => @index_context, 
                             :letter        => @index_letter,
                             :parent_entry  => @top_entry)
      # print "\t SECOND LEVEL: #{clean_text(element)}\n"
      @index.index_entries << entry
      
    end
    
    def handle_node_text element
      text = ''
      element.children.each do |child|
        text += clean_text(child)
      end
      text = text.gsub("\r\n","\n").strip
    end
    
    def clean_text node
      node.elem? ?  node.to_original_html : node.to_s
    end
    
    def handle_image_or_column name, node
      if name == "image"
        @image = node.attributes['src']
      elsif name == "col"
        @column = handle_node_text(node)
      end
    end
  
  end
  
end