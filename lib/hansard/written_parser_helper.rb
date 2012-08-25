module Hansard
end

module Hansard::WrittenParserHelper

  include Hansard::ParserHelper

  def load_doc
    unless @doc
      file_text = open(@file).read
      @doc = Hpricot.XML(file_text) 
    end
    @doc
  end

  def parse
    doc = load_doc
    type = get_root_name doc
    if type == expected_root_element
      create_written expected_root_element
    else
      raise "cannot create #{expected_root_element}, unrecognized type: " + type
    end
  end

  def get_initial_column written_type, doc
    if (col = doc.at("#{written_type}/col"))
      clean_html(col)
    elsif (col = doc.at('col'))
      next_column = clean_html(col).to_i
      (next_column - 1).to_s
    else
      nil
    end
  end

  YEAR_MONTH_DAY_PATTERN = regexp('(\d\d\d\d)_(\d\d)_(\d\d)')

  def get_date_for_written written_type
    if (date = @doc.at("#{written_type}/date"))
      date_text = clean_html(date)
      date = date.attributes['format']
    end
    filename_date = date_from_filename(@file)
    date = filename_date if filename_date
    date_text = Date.parse(date).strftime('%A %d %B %Y') unless defined? date_text
    return date, date_text
  end

  def begin_parse_of_written written_type
    @column = get_initial_column written_type, @doc
    date, date_text = get_date_for_written written_type

    @sitting = sitting_type.new({
      :start_column => @column,
      :title => handle_node_text(@doc.at("#{written_type}/title")),
      :date_text => date_text,
      :date => date,
      :data_file => @data_file
    })
  end

  DATA_WRAPPERS = %w[ol ul table quote]

  def handle_section(section_element, parent, type, ignore_child_sections=false)
    section = create_section(type)

    member_contribution = nil
    section_element.children.each do |node|
      case node.name
        when 'title'
          section.title = handle_node_text(node)
        when 'body'
          handle_section(node, section, get_body_model_class)
        when 'section'
          handle_section(node, section, Section) unless ignore_child_sections
        when 'col', 'image'
          if member_contribution
            handle_contribution_col(node, member_contribution) if node.name == 'col'
            handle_contribution_image(node, member_contribution) if node.name == 'image'
            member_contribution.text += node.to_original_html
          else
            handle_image_or_column node
          end
        when 'p'
          contribution = handle_written_contribution(node, section, member_contribution)
          member_contribution = contribution if contribution && contribution.is_a?(WrittenMemberContribution)
        else
          if DATA_WRAPPERS.include? node.name
            contribution = handle_written_contribution node, section, member_contribution
          else
            log "unexpected element in #{type}: " + node.name + ': ' + node.to_s
          end
      end if node.elem?

      raise_error_if_non_blank_text node, "unexpected text in #{type}: "
    end

    set_parent_on_section section, parent
  end

  def set_parent_on_section section, parent
    section.end_column = @column
    if parent.is_a? Sitting
      section.sitting = parent
    else
      section.parent_section = parent
    end
    parent.sections << section
  end

  def get_contribution_type_for_question element
    contribution_type = nil

    if (element.at('member') or element.at('membercontribution'))
      contribution_type = WrittenMemberContribution
    else
      contribution_type = ProceduralContribution
    end
    contribution_type
  end

  def handle_contribution_text element, contribution
    set_columns_and_images_on_contribution element, contribution
    text = element.to_original_html
    if text.starts_with?(':')
      text.sub!(':','')
      text.strip!
    end
    contribution.text += text
  end

  def create_written_contribution element
    contribution_type = get_contribution_type_for_question(element)

    contribution = contribution_type.new({
      :xml_id => element.attributes['id'],
      :column_range => @column, 
      :start_image => @image, 
      :end_image => @image, 
      :anchor_id => anchor_id
    })
    contribution.member_name = ''
    contribution.text = ''
    contribution
  end

  WRITTEN_QUESTION_NUMBERS_PATTERN = regexp('^(Q?\d+\.? and \d+\.?)$')
  WRITTEN_QUESTION_NUMBER_PATTERN = regexp('^(Q?\d+\.?)$')

  def handle_written_contribution(element, section, member_contribution)
    continuation_of_a_member_contribution = member_contribution && (!element.at('member'))

    if continuation_of_a_member_contribution
      contribution = member_contribution
    else
      contribution = create_written_contribution element
    end

    if contribution.is_a? WrittenMemberContribution
      if DATA_WRAPPERS.include? element.name
        contribution.text += '<'+element.name+'>'
      else
        contribution.text += '<p'
        if (xml_id = element.attributes['id'])
          contribution.text += %Q[ id="#{xml_id}"]
        end
        contribution.text += '>'
      end
    end

    element.children.each do |node|
      case node.name
        when 'member'
          handle_member_name(node, contribution)
        when 'col', 'image'
          handle_contribution_col(node, contribution) if node.name == 'col'
          handle_contribution_image(node, contribution) if node.name == 'image'
          contribution.text += node.to_original_html
        else
          handle_contribution_text(node, contribution)
      end if node.elem?

      if node.text?
        text = node.to_s.strip
        if (match = WRITTEN_QUESTION_NUMBERS_PATTERN.match text)
          contribution.question_no = match[1]
        elsif (match = WRITTEN_QUESTION_NUMBER_PATTERN.match text)
          contribution.question_no = match[1]
        else
          handle_contribution_text(node, contribution)
        end
      end
    end

    if contribution.is_a? WrittenMemberContribution
      if DATA_WRAPPERS.include? element.name
        contribution.text += '</'+element.name+'>'
      else
        contribution.text += '</p>'
      end
    end
    contribution.section = section

    if continuation_of_a_member_contribution
      nil
    else
      section.contributions << contribution
      contribution
    end
  end

  def create_written element_name
    begin_parse_of_written element_name
    first_image = first_col = first_date = first_title = nil

    @doc.at(element_name).children.each do |node|
      case node.name
        when 'group'
          handle_group(node)
        when 'section'
          handle_group(node)
        when 'title'
          first_title ? log_unexpected(node) : (first_title = node.to_s)
        when 'date'
          first_date ? log_unexpected(node) : (first_date = node.to_s)
        when 'col', 'image'
          handle_image_or_column node
        else
          log_unexpected(node)
      end if node.elem?

      raise_error_if_non_blank_text node, "unexpected text in writtenanswers element"
    end
    @sitting.volume = @source_file.volume
    @sitting.end_column = @column
    @sitting
  end

  def handle_group_children group, element, ignore_child_paragraphs=false
    element.children.each do |node|
      case node.name
        when 'title'
          # already handled
        when 'section'
          handle_section(node, group, Section)
        when 'image', 'col'
          handle_image_or_column node
        when 'p' 
          if ignore_child_paragraphs
            # ignore
          else  
            handle_written_contribution(node, group, nil) 
          end
        when 'body'
          section = create_section(Section)
          section.title = group.title
          handle_section(node, section, get_body_model_class)
          set_parent_on_section section, group
        else
          log 'unexpected element in group: ' + node.name + ': ' + node.to_s
      end if node.elem?

      raise_error_if_non_blank_text node, 'unexpected text in group: '
    end
  end

  def handle_a_group(element)
    group = create_section(get_group_model_class)
    @last_group = group
    if element.children_of_type('title').size > 0
      group.title = handle_node_text(element.children_of_type('title').first)
    end
    handle_group_children group, element
    group.end_column = @column
    group.sitting = @sitting
    @sitting.groups << group
  end
  
  def create_group(element)
    group = create_section(get_group_model_class)
    handle_section(element, group, Section)
    group.end_column = @column
    group.sitting = @sitting
    @sitting.groups << group
  end

  def handle_group(element)
    if sitting_type == LordsWrittenStatementsSitting
      create_group(element)
    elsif (element.name == 'section' && (element.children_of_type('p').size > 0) && @last_group)
      handle_section(element, @last_group, Section, ignore_child_sections=true)
      group = @last_group
      handle_group_children group, element, ignore_child_paragraphs=true
    elsif (element.name == 'section' && (element.children_of_type('p').size > 0) )
      create_group(element)
    else
      handle_a_group(element)
    end
  end

  def log_unexpected node
    log "unexpected element under writtenanswers element: " + node.name + ': ' + node.to_s
  end
end
