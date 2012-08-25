require 'rubygems'
require 'open-uri'
require 'hpricot'

class Hansard::HouseParser

  include Hansard::ParserHelper

  attr_reader :column, :image, :sitting
  attr_accessor :anchor_integer, :division_handler

  def initialize file, data_file=nil, source_file=nil, parse_divisions=true
    @anchor_integer = 1
    @data_file = data_file
    @unexpected = false
    @file = file
    @source_file = source_file
    self.division_handler = parse_divisions ? Hansard::DivisionHandler.new : nil
  end

  PART_2 = regexp('part_2')

  def load_doc
    unless @doc
      file_text = open(@file).read
      @doc = Hpricot.XML(file_text) 
    end
    @doc
  end

  def parse
    doc = load_doc
    case (type = get_root_name(doc))
      when 'housecommons'
        create_house_sitting('housecommons', HouseOfCommonsSitting, doc)
      when 'westminsterhall'
        create_house_sitting('westminsterhall', WestminsterHallSitting, doc)
      when 'houselords'
        create_house_sitting('houselords', PART_2.match(@file) ? HouseOfLordsReport : HouseOfLordsSitting, doc)
      when 'grandcommitteereport'
        create_house_sitting('grandcommitteereport', GrandCommitteeReportSitting, doc)
      else
        raise 'cannot create sitting, unrecognized type: ' + type
    end
  end

  def year
    @sitting.year
  end

  def obtain_division year, header_values, node, section=nil
    raise "not prepared to handle division in #{@sitting.class.to_s}"
  end

  def is_a_division_result? text
    division_handler ? Division.is_a_division_result?(text) : false
  end

  def add_division_result section, procedural
    division_handler ? division_handler.add_division_result(section, procedural) : false
  end

  def cells_from_row row
    (row/'th').empty? ? (row/'td') : (row/'th') 
  end
  
  def handle_division_table table, division
    index = (division_table_width == 3) ? 2 : 1
    rows = (table/'tr')

    column_cells = []

    0.upto(index) do |col_index|
      column_cells << rows.collect{ |r| cells_from_row(r)[col_index] }
    end

    last_column_cells = column_cells.last

    row_index = 0

    rows.each do |row|
      col = 0
      cells_from_row(row).each do |cell|
        if column_cells[col] && (row_index + 1) < column_cells[col].length
          cell_below = column_cells[col][row_index + 1]
        else
          cell_below = nil
        end
        handle_division_table_cell cell, division, last_column_cells, cell_below 
        col = col.next
      end
      row_index = row_index.next
    end
    @ignore_vote_names_list.clear if @ignore_vote_names_list

    complete_remaining_votes division
  
  end

  def handle_division_table_cell cell, division, last_column_cells, cell_below
    text = text_from_cell cell
    text_below = text_from_cell cell_below
    if division_handler
      handle_the_vote text, cell, division, last_column_cells, text_below unless text.blank? 
    end
  end

  def text_from_cell cell
    cell ? (cell.at('b') ? cell.at('b').inner_text.strip : cell.inner_text.strip) : nil
  end

  def complete_remaining_votes division
    unless @teller_remainder_text.blank?
      name = @teller_remainder_text.chomp('.')
      @teller_remainder_text = nil
      handle_vote name, division, @vote_type, nil
    end
  end

  def division_table_width
    (year < 1981) ? 3 : 2
  end

  def last_division_on_division_stack
    division_handler ? division_handler.last_division : nil
  end

  def create_division_placeholder node, section, header_values
    division, is_new_division = obtain_division year, header_values, node, section

    if division && division.is_a?(UnparsedDivisionPlaceholder)
      return division, false
    elsif division
      if node.name == 'table'
        handle_division_table node, division
      else
        node.children.each do |child|
          case child.name
            when 'table'
              handle_division_table child, division
            when 'col', 'image'
              handle_image_or_column child
            else
              log 'unexpected element in non_procedural_section: ' + child.name + ': ' + node.to_s
          end if child.elem?
        end
      end

      placeholder_text = clean_html(node).strip
      placeholder = DivisionPlaceholder.new({
        :xml_id => node.attributes['id'],
        :text => placeholder_text, 
        :anchor_id => anchor_id, 
        :column_range => column,
        :start_image => image, 
        :end_image => image
      })
      placeholder.division = division
      return placeholder, is_new_division
    else
      puts 'failed to obtain division for node: ' + node.inspect
      return nil, false
    end
  end
  
  def get_header_values table_node
    first_row = (table_node/'tr[1]')
    cells_from_row(first_row).collect{ |cell| cell.to_plain_text }
  end

  def handle_division(node, section, header_values=nil)
    return handle_unparsed_division(node, section) unless division_handler
    table = (node/'table[1]')
    header_values = get_header_values(table) unless header_values
    placeholder, is_new_division = create_division_placeholder(node, section, header_values)
    unless placeholder.is_a?(UnparsedDivisionPlaceholder)
      rescue_division_parsing_exception do
        division_handler.handle_division node, section, placeholder, is_new_division 
      end
    end
  end

  def add_division_after_divided_text section, procedural
    division_handler.add_division_after_divided_text section, procedural
  end

  def log_context node
    if @log_context_text
      log 'Context    ' + node.to_s
      @log_context_text = false
    end
  end

  def handle_member_contribution_element contribution, element, section, status
    if status != :after_member_contribution
      case element.name
        when 'member'
          handle_member_name element, contribution
          status = :between_member_and_contribution
        when 'i'
          add_to_procedural_note(contribution, element)
        when 'membercontribution'
          handle_contribution_text element, contribution
          status = :after_contribution
        when 'ol'
          set_columns_and_images_on_contribution element, contribution
          contribution.text += clean_text(element.to_s)
        when 'quote'
          status = :after_member_contribution
          section.add_contribution contribution
          handle_quote_contribution element, section
        when 'sup'
          contribution.text = '' if contribution.text.nil?
          contribution.text += ("<sup>#{clean_text(element.to_s)}</sup>")
        else
          log 'Unhandled element in member contribution    ' + element.name + '    ' + element.to_s
      end
    elsif element.name == 'quote'
      handle_quote_contribution element, section
    else
      log 'Unhandled element in member contribution    ' + element.name + '    ' + element.to_s
    end
    status
  end

  def handle_member_contribution_node contribution, node, section, status
    
    if node.elem?
      status = handle_member_contribution_element contribution, node, section, status

    elsif node.text?
      text = node.to_s.strip
      if text.empty? || text == ':' 
      elsif text == '*' || TimeContribution::OLD_TIME_TEXT.match(text) 
        contribution.prefix = '' unless contribution.prefix
        contribution.prefix += text
      elsif status == :before_member
        if text.strip == "The" 
          text += ' ' 
          contribution.member_name = text
        else
          contribution.prefix = '' unless contribution.prefix
          contribution.prefix += text
        end
      elsif status == :between_member_and_contribution 
        add_to_procedural_note(contribution, node)
      else
        log "Unhandled text    Column #{@column}    " + text
        @log_context_text = true
      end
    end
    status
  end

  def add_to_procedural_note contribution, node
    if contribution.procedural_note
      contribution.procedural_note += node.to_s
    else
      contribution.procedural_note = node.to_s
    end
  end
  
  def make_contribution id
    MemberContribution.new({
       :xml_id => id,
       :anchor_id => anchor_id,
       :column_range => @column,
       :member_name => '',
       :start_image => image, 
       :end_image => image
    })
  end

  ENDS_IN_NUMBER = regexp('\d\.(<lb/>)?$')

  def handle_member_contribution element, section
    contribution = make_contribution element.attributes['id']
    status = :before_member
    @log_context_text = false
    element.children.each do |node|
      log_context node
      status = handle_member_contribution_node(contribution, node, section, status)
    end

    section.add_contribution contribution unless status == :after_member_contribution
    handle_divided_text_in_member_contribution contribution, section if contribution.text && division_handler && ENDS_IN_NUMBER.match(contribution.text)
    contribution
  end

  def handle_divided_text_in_member_contribution contribution, section
    # override when needed
  end

  def create_house_divided_contribution text
    procedural = ProceduralContribution.new({
      :column_range => @column,
      :anchor_id => anchor_id,
      :start_image => image, 
      :end_image => image,
      :text => text})
  end

  def handle_time_contribution node, section, time_text
    time = TimeContribution.new({
      :xml_id => node ? node.attributes['id'] : nil,
      :anchor_id => anchor_id,
      :column_range => column,
      :text => node ? clean_html(node) : time_text, 
      :start_image => image, 
      :end_image => image})
    section.add_contribution time
    time
  end

  PROCEDURAL_QUESTION_NUMBER_PATTERN = regexp('^(\d+\.?)')

  def create_procedural_contribution node, section
    procedural = ProceduralContribution.new({
      :xml_id => node.attributes['id'],
      :anchor_id => anchor_id,
      :column_range => @column, 
      :start_image => image, 
      :end_image => image })
    procedural.text = handle_contribution_text(node, procedural)

    node.children.each do |part|
      if (part.elem? and part.name == 'member')
        procedural.member_name = '' unless procedural.member_name
        handle_member_name part, procedural
      end
    end

    if (match = PROCEDURAL_QUESTION_NUMBER_PATTERN.match procedural.text)
      procedural.question_no = match[1]
    end

    style_atts = node.attributes.reject{|att, value| att == 'id'}

    procedural.style = returning([]) do |styles|
      style_atts.each { |att, value| styles << "#{att}=#{value}" }
    end.join(" ")

    procedural.section = section
    procedural
  end

  def handle_procedural_contribution node, section

    procedural = create_procedural_contribution node, section

    if division_handler && is_divided_text?(procedural.text)
      add_division_after_divided_text section, procedural

    elsif is_a_division_result? procedural.text
      add_division_result section, procedural

    else
      section.contributions << procedural
    end

    procedural
  end

  def handle_paragraph node, section
    inner_html = clean_html(node).strip
    if TimeContribution::TIME_PATTERN.match inner_html
      time_text = $0
      handle_time_contribution node, section, time_text
    elsif inner_html.include? 'membercontribution'
      handle_member_contribution node, section
    elsif inner_html.starts_with?('<table') && inner_html.ends_with?('</table>')
      handle_table_or_division node.at('table'), section, node.attributes['id']
    else
      handle_procedural_contribution node, section
    end
  end

  def handle_title node, section
    title = handle_node_text(node).sub("\n", " ").squeeze(" ")

    if title.blank?
      text = handle_node_text(node.at('../p[1]'))
      if title_match = /(\[?MINUTES?\.?\]?|\[.*?\])/.match(text)
        title_text = title_match[1]
        title = title_text.gsub('&#x2014;','').sub("\n", " ").squeeze(" ")
      else
        title = 'Summary of Day'
      end
    end
    section.start_column = self.column
    section.title = title
  end

  def handle_section_element_children node, section
    case node.name
      when 'title'
        handle_title node, section
      when 'p'
        handle_paragraph node, section
      when 'quote'
        handle_quote_contribution node, section
      when 'col', 'image'
        handle_image_or_column node
      when 'section'
        handle_section_element node, section
      when 'table'
        handle_table_or_division node, section
      when 'division'
        handle_division(node, section) 
      when 'ul'
        contribution = handle_procedural_contribution node, section
        contribution.text = "<ul>\n"+contribution.text+"\n</ul>"
      when 'ol'
        contribution = handle_procedural_contribution node, section
        contribution.text = "<ol>\n"+contribution.text+"\n</ol>"
      else
        log 'unexpected element in section: ' + node.name + ': ' + node.to_s
    end if node.elem?
  end

  def handle_unparsed_division node, section
    placeholder_text = clean_html(node).strip
    unparsed_divison = UnparsedDivisionPlaceholder.new({
      :text => placeholder_text
    })
    unparsed_divison.section = section
    unparsed_divison.anchor_id = anchor_id
    unparsed_divison.xml_id = section.contributions.last.xml_id if !section.contributions.empty?
    section.contributions << unparsed_divison
    unparsed_divison
  end

  def wrap_as_division node
    division = "<division>#{node.to_s}</division>"
    Hpricot.XML(division).at('division')
  end

  def series_number
    @source_file ? @source_file.series_number : nil
  end

  def handle_table_or_division node, section, xml_id=nil
    header_values = get_header_values(node)
    if start_of_division?(year, header_values, series_number) || (header_values.size == 1 && header_values.first.starts_with?('NOES') )
      division_node = wrap_as_division(node)
      handle_division(division_node, section) 
    else
      handle_table_element node, section, xml_id
    end
  end

  def handle_section_element section_element, parent
    section = create_section(Section)
    section_element.children.each do |node| 
      handle_section_element_children node, section
    end

    section.end_column = @column
    parent.add_section section
  end

  def get_contribution_type_for_question element
    contribution_type = nil

    if (element.at('member') or element.at('membercontribution'))
      contribution_type = MemberContribution
    elsif element.at('quote')
      contribution_type = QuoteContribution
    else
      contribution_type = ProceduralContribution
    end

    contribution_type
  end

  def handle_element_in_question_contribution node, contribution, element, status
    case node.name
      when 'member'
        handle_member_name node, contribution
        status = :between_member_and_contribution
      when 'membercontribution'
        handle_contribution_text node, contribution
        status = :after_contribution
      when 'i'
        if status == :in_contribution
          contribution.text += node.to_s
        else
          add_to_procedural_note(contribution, node)
        end
      when 'table'
        contribution.text += node.to_s
      when 'sup'
        if status == :before_member
          contribution.prefix = '' unless contribution.prefix
          contribution.prefix += node.to_s
        elsif status == :in_contribution
          contribution.text += node.to_s
        elsif status == :after_contribution
          contribution.text += node.to_s
        else
          raise 'Unhandled element in Question contribution    ' + node.name + '    ' + node.to_s
        end
      when 'col', 'image'
        handle_image_or_column node
        contribution.text += node.to_s if status == :in_contribution
      when 'b'
        if status == :between_member_and_contribution
          contribution.member_name += node.inner_html
        else
          contribution.text += node.to_s
        end
      when 'lb'
        if status == :in_contribution
          contribution.text += node.to_s.sub('<lb></lb>', '<lb/>')
        end
      when 'ob'
        contribution.text += node.to_s
      else
        raise 'Unhandled element in Question contribution    ' + node.name + '    ' + node.to_s
    end

    status
  end

  QUESTION_NUMBERS_PATTERN = regexp('^(Q?\d+\.? and \d+\.?)')
  QUESTION_NUMBER_PATTERN = regexp('^(Q?\d+\.?)')
  ALTERNATE_NUMBER_PATTERN = regexp('(\[\d+\])')

  def handle_text_in_question_contribution node, contribution, element, status
    text = node.to_s.strip
    if (match = QUESTION_NUMBERS_PATTERN.match text)
      contribution.question_no = match[1]
    elsif (match = QUESTION_NUMBER_PATTERN.match text)
      contribution.question_no = match[1]
    elsif text.size > 0
      if text == '*' and status == :before_member
        contribution.prefix = '' unless contribution.prefix
        contribution.prefix += text
      elsif contribution.member_name.size == 0
        contribution.member_name = text.gsub("\r\n","\n").strip + ' '
      elsif !@unexpected
        if element.at('membercontribution')
          if text == ':'
            contribution.text += node.to_s.squeeze(' ')
          elsif text == ']' || text == '.'
            contribution.text += text
          elsif (status == :between_member_and_contribution) && (text == '(')
            contribution.procedural_note = '('
          elsif (status == :between_member_and_contribution) && (text == ')')
            contribution.procedural_note += ')'
          elsif status == :after_contribution && (match = ALTERNATE_NUMBER_PATTERN.match text)
            contribution.text += " #{text}"
          else
            log 'unexpected text: ' + text + ' in contribution ' + contribution.inspect
            log 'will suppress rest of unexpected messages'
            @unexpected = true
          end
        else
          status = :in_contribution
          suffix = node.to_s.ends_with?("\r\n") ? "\n" : ''
          prefix = node.to_s.starts_with?("\r\n") ? "\n" : ''
          contribution.text += prefix + text.gsub("\r\n","\n").strip + suffix
        end
      end
    elsif node.to_s == "\r\n"
      if status == :in_contribution
        contribution.text += "\n"
      end
    end
    return status
  end

  def handle_question_contribution element, question_section
    contribution_type = get_contribution_type_for_question(element)

    if contribution_type == QuoteContribution
      handle_quote_contribution element, question_section
    elsif contribution_type == ProceduralContribution
      handle_procedural_contribution element, question_section
    else
      contribution = contribution_type.new({
         :xml_id => element.attributes['id'],
         :column_range => @column,
         :member_name => '',
         :anchor_id => anchor_id,
         :start_image => image, 
         :end_image => image,
         :text => ''})

      status = :before_member
      element.children.each do |node|
        if node.elem?
          status = handle_element_in_question_contribution(node, contribution, element, status)

        elsif node.text?
          status = handle_text_in_question_contribution(node, contribution, element, status)
        end
      end

      question_section.add_contribution contribution
      contribution
    end
  end

  ORDERS_OF_DAY_PATTERN = regexp('orders of the day', 'i')
  BUSINESS_OF_HOUSE_PATTERN = regexp('business of the house', 'i')
  PERSON_IN_CHAIR_PATTERN = regexp('\[?(?:.*,)?(.*?)in the chair\.?(<\/i>)?\]?\s*$', 'i')

  def is_orders_of_the_day? title
    ORDERS_OF_DAY_PATTERN.match(title)
  end

  def is_business_of_the_house? title
    BUSINESS_OF_HOUSE_PATTERN.match(title)
  end

  def is_person_in_chair? text
    ! PERSON_IN_CHAIR_PATTERN.match(text.downcase).nil?
  end

  def get_chairman text
    if match = PERSON_IN_CHAIR_PATTERN.match(text)
      match[1].strip
    end
  end
  
  def contains_title? section
    return true if section.at('title')
    return true if section.at('p[1]/text()').to_s[/^\[.*?\]/] 
    return true if (section/'../section/p').size == 1 
    return false
  end

  def handle_section section, debates
    if section.inner_text.strip.blank?
      # 'ignoring empty section with no title'
    elsif contains_title?(section)
      handle_section_element section, debates
    else
      raise 'unexpected to find section with no title: ' + section.to_s
    end
  end

  def handle_debates sitting, debates
    sitting.debates = create_section(Debates) unless sitting.debates
    debates.children.each { |node| handle_child_element node, sitting }
    sitting.end_column = @column
  end

  def create_house_sitting house_type, house_model, doc
    title = clean_html(doc.at(house_type + '/title')).gsub('<lb></lb>','')
    if title == 'Written Ministerial Statements' && house_model == HouseOfCommonsSitting
      log 'not creating sitting as housecommons file only contains Written Ministerial Statements'
      return nil
    end

    @column = clean_html(doc.at('col'))
    first_image = doc.at('image')
    @image = first_image[:src] if first_image

    date_element = doc.at(house_type + '/date')
    date = date_element.attributes['format'] if date_element

    # use the filename date from the splitter (it's been corrected)
    filename_date = date_from_filename(@file)
    date = filename_date if filename_date
    @sitting = house_model.new({
      :start_column => @column,
      :title => title,
      :date_text => clean_html(date_element),
      :date => date,
      :data_file => @data_file
    })

    chair_element = doc.search("p, title")[0,10].detect{ |ele| ele.inner_text.size < 200 && ele.inner_text =~ PERSON_IN_CHAIR_PATTERN }
    @sitting.chairman = get_chairman(chair_element.inner_text.to_s) if chair_element

    if house_type == 'grandcommitteereport'
      handle_grand_committee_report  @sitting, doc.at(house_type)
    else
      debates_list = doc.search(house_type + '/debates')
      debates_list.each do |debates|
        handle_debates @sitting, debates
      end
    end
    if division_handler
      rescue_division_parsing_exception { division_handler.populate_last_division } 
    end
    @sitting.volume = @source_file.volume if @source_file
    @sitting
  end
  
  def rescue_division_parsing_exception
    begin
      yield
    rescue Hansard::DivisionParsingException => e
      @data_file.log_exception e
      @data_file.add_log 'continuing with division matching turned off'
      self.division_handler = nil
    end
  end

end
