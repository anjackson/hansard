require 'rubygems'
require 'open-uri'
require 'hpricot'

class Hansard::WrittenAnswersParser
 
  def initialize file, logger=nil
    @logger = logger
    @unexpected = false
    @doc = Hpricot.XML open(file)
  end

  def log text
    @logger.add_log text if @logger
  end

  def parse
    type = @doc.children[0].name

    if type == 'writtenanswers'
      create_written_answers
    else
      raise 'cannot create sitting, unrecognized type: ' + type
    end
  end

  def create_written_answers
    @column =  clean_html(@doc.at('writtenanswers/col'))
    @image =  @doc.at('writtenanswers/image').attributes['src']

    sitting = WrittenAnswersSitting.new({
      :start_column => @column,
      :start_image_src => @image,
      :title => clean_html(@doc.at('writtenanswers/title')),
      :date_text => clean_html(@doc.at('writtenanswers/date')),
      :date => @doc.at('writtenanswers/date').attributes['format']
    })

    if (texts = (@doc/'writtenanswers/p'))
      sitting.text = ''
      texts.each do |text|
        sitting.text += text.to_s
      end
    end

    if (groups = (@doc/'writtenanswers/group'))
      groups.each do |group|
        handle_group(group, sitting)
      end
    end
    sitting
  end
  
  def handle_group(group_element, sitting) 
    group = WrittenAnswersGroup.new({
      :start_column => @column,
      :start_image_src => @image
    })

    group_element.children.each do |node|
      if node.elem?
        name = node.name
        if name == 'title'
          group.title = handle_node_text(node)
        elsif name == 'section'
          handle_section(node, group, Section)
        elsif name == 'image' or name == 'col'
          handle_image_or_column(name, node)
        else
          log 'unexpected element in group: ' + name + ': ' + node.to_s
        end
      else
        log 'unexpected text in group: ' + node.to_s + node.to_s.strip if !node.to_s.strip.blank?
      end
    end

    group.sitting = sitting
    sitting.groups << group
  
  end
  
  def handle_section(section_element, group, type)
    section = type.new({
      :start_column => @column,
      :start_image_src => @image
    })
    section_element.children.each do |node|
      if node.elem?
        name = node.name
        if name == 'title'
          section.title = handle_node_text(node)
        elsif name == 'body'
          handle_section(node, section, WrittenAnswersBody)
        elsif name == 'image' or name == 'col'
          handle_image_or_column(name, node)
        elsif name == 'p'
          handle_written_question_contribution(node, section)
        else
          log "unexpected element in #{type}: " + name + ': ' + node.to_s
        end
      else
        log "unexpected text in #{type}: " + node.to_s.strip if !node.to_s.strip.blank?
      end
    end
    
    section.parent_section = group
    group.sections << section
    
  end
  
  def get_contribution_type_for_question element
    contribution_type = nil

    if (element.at('member') or element.at('membercontribution'))
      contribution_type = MemberContribution
    else
      contribution_type = ProceduralContribution
    end
    contribution_type
  end
  
  def handle_written_question_contribution(element, section)
    contribution_type = get_contribution_type_for_question(element)

    contribution = contribution_type.new({
      :xml_id => element.attributes['id'],
      :column_range => @column,
      :image_src_range => @image
    })

    contribution.member = ''
    contribution.text = ''
    element.children.each do |node|
      if node.elem?
        name = node.name
        if name == 'member'
          handle_member_name(node, contribution)
        elsif (name == 'col' or name == 'image')
          handle_image_or_column name, node
        else
          contribution.text += "<#{name}>"
          handle_contribution_text(node, contribution)
          contribution.text += "</#{name}>"
          # log "unexpected element in #{contribution_type}: " + name + ': ' + node.to_s
        end
      elsif node.text?
       contribution.text += node.to_s.gsub("\r\n","\n")
      end
    end

    contribution.section = section
    section.contributions << contribution
    
  end
  
  def handle_member_name element, contribution
    element.children.each do |node|
      if node.text?
        text = node.to_s.strip
        contribution.member += text if text.size > 0

      elsif node.elem?
        if node.name == 'memberconstituency'
          contribution.member_constituency = clean_html(node)
        else
          log 'unexpected element in member_name: ' + name + ': ' + node.to_s
        end
      end
    end
  end
  
  def handle_contribution_text element, contribution
    (element/'col').each do |col|
      handle_image_or_column "col", col
      contribution.column_range += ','+@column
    end
    (element/'image').each do |image|
      handle_image_or_column "image", image
      contribution.image_src_range += ','+@image
    end
    contribution.text += handle_node_text element
  end
  
  def handle_image_or_column name, node
    if name == "image"
      @image = node.attributes['src']
    elsif name == "col"
      @column = clean_html(node)
    end
  end
  
  def handle_node_text element
    text = ''
    element.children.each do |child|
      text += child.elem? ?  child.to_original_html : child.to_s
    end
    text = text.gsub("\r\n","\n").strip
  end
  
  def clean_html node
    node.inner_html.chars.gsub("\r\n","\n").to_s
  end
  
end