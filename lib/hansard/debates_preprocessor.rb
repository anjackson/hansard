module Hansard
  
  class DebatesPreprocessor
    
    PREAMBLE_TITLE = 'Preamble'
    
    def outfile(infile, overwrite)
      outfile = overwrite ? infile : infile+".clean"
    end
    
    def clean_file(infile, overwrite)
      outfile = outfile(infile, overwrite)
      file_text = open(infile).read
      contents = Hpricot.XML(file_text)  
      contents = clean_empty_appendices contents 
      contents = clean_empty_columns contents  
      contents = create_debates_tag contents
      contents = group_content_into_sections contents
      contents = move_paras_into_debates contents
      contents = move_orphan_paras_into_sections contents
      contents = title_first_section contents
      f = File.new(outfile, 'w')
      f.write(contents.to_original_html)
      f.close
    end
    
    def clean_empty_appendices contents
      empty_appendices = contents.search("appendix[text()='']")
      empty_appendices.remove
      contents
    end
  
    def clean_empty_columns contents
      root = contents.root
      empty_columns = root.search("col[text()='']")
      empty_columns.remove
      contents
    end
    
    def create_debates_tag contents
      root = contents.root
      return contents if root.at('debates')
      content_nodes = []
      date_node = root.at('date')
      title_node = root.at('title')
      root.each_child do |child|
        content_nodes << child if child.text? and ! child.to_s.strip.blank?
        next unless child.elem?
        content_nodes << child unless child.name == 'date' or child.name == 'title'
      end  
      replacement_content = ["<#{root.name}>", 
                             date_node.to_s, 
                             title_node.to_s, 
                             '<debates>', 
                             content_nodes.to_s, 
                             '</debates>', 
                             "</#{root.name}>"]
      contents = Hpricot.XML(replacement_content.join("\n"))
    end
    
    def group_content_into_sections contents
      debates = contents.at('debates')
      return contents if debates.at('section')
      paras = []
      debates.each_child{ |child| paras << child }
      replacement_text = sections_from_paras(paras)
      debates.inner_html = replacement_text
      contents
    end
    
    def sections_from_paras(element_list)
      replacement_text = ''
      title = ''
      section = []
      element_list.each do |element|
        if is_section_start? element 
          replacement_text = add_section_text(title, replacement_text, section)
          title = extract_section_title element
          section = []
        end
        section << element
      end
      add_section_text(title, replacement_text, section)
    end
    
    def add_section_text title, text, section
      if !section.to_s.strip.blank?
        if section.all?{|element| element.text? or (element.name == 'image' or element.name == 'col')}
          text += section.map{ |s| s.to_original_html }.to_s
        else
          title = PREAMBLE_TITLE if title.strip.blank?
          text += "<section><title>#{title}</title>#{section.map{ |s| s.to_original_html }}</section>" 
        end
      end
      text
    end
    
    TITLE = /\A\s*\[?([^\[]+)\](?:&#x2014;)?(.*)/m
    
    def extract_section_title node
      title = ''
      title_node = get_title_node(node)
      if title_node
        title_text = title_node.inner_html
        title_match = TITLE.match(title_text)
        if title_match
          title = title_match[1]
          title = title.gsub(/(<col>(.*?)<\/col>)/, '') 
          title = title.gsub(/(<[^>]*>(.*?)<\/[^>]*>)/, '\2')
          title = title.gsub("\n", '').split.join(' ')
          title_node.inner_html = title_match[2].strip 
        end
      end
      title
    end
    
    def get_title_node node
      member_nodes = node.search("member").select { |ele| has_title? ele }
      if !member_nodes.empty?
        return member_nodes.first
      else 
        if has_title? node 
          return node
        end
        return nil
      end
    end
    
    def has_title? node
      return true if node.inner_html =~ /\APRAYERS/
      return false if node.inner_text =~ /\A\s*\[?Amendments? No/i
      if match = TITLE.match(node.inner_text)
        if /in the Chair\.?$/.match(match[1])
          return false
        else
          return true
        end
      end
      return false
    end
    
    def is_section_start? node
      return false unless node.elem?
      return false unless node.name == 'p'
      return false unless get_title_node(node)
      return true
    end
    
    def is_minutes? node
      return true if node.inner_text =~ /^\[?M[I|T]NUTES?/i
      return false
    end
    
    def title_first_section contents
      first_section = contents.root.at('debates/section')
      return contents unless first_section
      title = first_section.at('title')
      title.inner_html = PREAMBLE_TITLE if title.inner_html.blank?
      return contents
    end
    
    def move_paras_into_debates contents
      root = contents.root
      para_outside_debates = root.at('/p')   
      debates_tags = root.search('debates')
      
      while para_outside_debates
        para_list = get_following_paras(para_outside_debates)
        replacement_text = sections_from_paras(para_list)
        insert_into_closest_debates_tag(para_outside_debates, replacement_text, debates_tags)
        para_list.each{ |element| element.swap('') }
        para_outside_debates = root.at('/p')
      end  
      contents 
    end
    
    def insert_into_closest_debates_tag(para, replacement_text, debates_tags)
      debates_tags.each do |debates|
        if para.node_position < debates.node_position
          debates_elements = Hpricot::Elements[debates]
          debates_elements.prepend(replacement_text)
          return
        end
      end
      last_debates_elements = Hpricot::Elements[debates_tags.last]
      last_debates_elements.append(replacement_text)
    end
    
    def get_following_paras(node)
      para_list = []
      current_node = node
      while current_node and (!current_node.elem? or ['p', 'image', 'col'].include? current_node.name)
         para_list << current_node
         current_node = current_node.next_node
      end
      para_list
    end
    
    def move_orphan_paras_into_sections contents
      orphan_para = contents.root.at('debates/p')
      debates_tag = contents.root.search('debates')
      while orphan_para
        para_list = get_following_paras(orphan_para)
        current_node = orphan_para
        while current_node and current_node.name != 'section'
          current_node = current_node.previous_sibling
        end
        if current_node
          current_node.inner_html = current_node.inner_html + para_list.to_s
        else
          replacement_text = sections_from_paras(para_list)
          debates_tag.prepend(replacement_text)
        end
        para_list.each{ |element| element.swap('') }
        orphan_para =  contents.root.at('debates/p')
      end  
      contents
    end
    
  end
  
end