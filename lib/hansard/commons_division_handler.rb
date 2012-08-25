module Hansard
end

module Hansard::CommonsDivisionHandler

  def start_of_division? year, header_values, series_number=nil
    CommonsDivision.start_of_division?(year, header_values, series_number)
  end

  def continuation_of_division? year, values
    CommonsDivision.continuation_of_division? year, values
  end

  def obtain_division year, header_values, node, section=nil
    if start_of_division?(year, header_values)

      if header_values.size > 1
        first_row = node.at("table/tr[1]")
        header_cells = cells_from_row(first_row)
        division_name = header_cells.first.to_plain_text
        time_text = header_cells[division_table_width-1].to_plain_text

        return new_division(division_name, time_text), is_new = true
      else
        return new_division(nil, nil), is_new = true
      end

    elsif continuation_of_division?(year, header_values)
      existing_division = last_division_on_division_stack

      if existing_division
        return existing_division, is_new = false
      else
        @vote_type = AyeVote
        return new_division(nil, nil), is_new = true
      end
    else
      raise Hansard::DivisionParsingException, 'Unexpected table in division: ' + header_values.inspect
    end
  end

  def new_division division_name, time_text
    CommonsDivision.new({
      :name => division_name,
      :time_text => time_text
    })
  end

  def handle_vote text, division, vote_type, text_below
    @ignore_vote_names_list = [] unless @ignore_vote_names_list

    unless text.blank? || @ignore_vote_names_list.include?(text) || is_nil_name?(text)
      log "vote_type nil: #{division.inspect} text:#{text}, " unless vote_type

      multi_line_constituency = is_multi_line_constituency?(text, text_below)
      @ignore_vote_names_list << text_below if multi_line_constituency

      vote = create_vote(text, text_below, multi_line_constituency, vote_type)
      vote.division = division
      division.votes << vote
    end
  end

  def is_multi_line_constituency? text, text_below
    (text.include?('(') && !text.include?(')') && text_below && text_below.ends_with?(')') && !text_below.include?('(') )
  end

  def create_vote text, text_below, multi_line_constituency, vote_type
    parts = text.split('(')
    name = parts[0].strip.sub(' arid ',' and ').sub(' sad ',' and ')
    name = handle_teller_name(name) if vote_type.is_teller?

    vote = vote_type.new({
      :name => name,
      :column => @column,
    })
    if parts.size > 1
      vote.constituency = parts[1].chomp(')')
      if multi_line_constituency
        vote.constituency = "#{vote.constituency} #{text_below}".chomp(')').squeeze(' ')
      end
    elsif text_below && text_below[/^\((.+)\)$/]
      vote.constituency = $1
      @ignore_vote_names_list << text_below
    end

    vote
  end

  def handle_teller_name name
    name.chomp!(' and')
    if name.include? ' and '
      names = name.split(' and ')
      name = names[0].strip
      @teller_remainder_text = names[1]
    elsif !@teller_remainder_text.blank?
      name = (@teller_remainder_text + ' ' + name).strip.squeeze(' ').chomp('.')
      @teller_remainder_text = nil
    end
    name
  end

  POTENTIAL_TIME = regexp('(\d(\.?:?\d?\d?)?\s?([ap]\.?\s?m\.?|noon))|\d\d?[\.:]\d\d', 'i') unless defined? POTENTIAL_TIME
  DIVISION = regexp('^\[?Divisi?on', 'i') unless defined? DIVISION

  def handle_teller_names_on_same_line ayes_or_noes, text, division
    if text.sub('&#x2014;','')[/teller(s)? for the #{ayes_or_noes}(.+)$/i]
      names = $2.strip.chomp('.').chomp(':')
      handle_vote(names, division, @vote_type, nil) unless names.blank? || names.size < 5
    end
  end

  def handle_the_vote text, cell, division, last_column_cells, text_below=nil
    begin
      if DIVISION.match text
        # it's the division number, ignore
      elsif (POTENTIAL_TIME.match text)
        resolver = TimeResolver.new(text)
        division.time = resolver.time if resolver.is_time? && !division.time
      elsif is_ayes? text
        @vote_type = AyeVote
      elsif is_noes? text
        complete_remaining_votes division
        @vote_type = NoeVote
      elsif is_ayes_teller? text
        @vote_type = AyeTellerVote
        handle_teller_names_on_same_line 'ayes', text, division
      elsif is_noes_teller? text
        @vote_type = NoeTellerVote
        handle_teller_names_on_same_line 'noes', text, division
      else
        vote_type = @vote_type
        if @vote_type == AyeTellerVote && !last_column_cells.include?(cell)
          vote_type = AyeVote
        elsif @vote_type == NoeTellerVote && !last_column_cells.include?(cell)
          vote_type = NoeVote
        end
        handle_vote text, division, vote_type, text_below
      end
    rescue Exception => e
      raise Hansard::DivisionParsingException, e.to_s
    end
  end

  COMMONS_DIVIDED_PATTERN = regexp('ayes?\s(\d+)\snoes\s(\d+)?') unless defined? COMMONS_DIVIDED_PATTERN

  def is_divided_text? text
    text = String.new text.downcase
    text.tr!(':,;.', ' ')
    text.squeeze!(' ')
    COMMONS_DIVIDED_PATTERN.match(text.sub("'",' ').squeeze(' ')) ? true : false
  end

  def is_ayes? text
    normalized_text = text.downcase.strip.chomp('.').strip
    return true if /^a(y|v)es\??$/.match(normalized_text)
    return false
  end

  def is_noes? text
    text.downcase.strip.chomp('.').strip == 'noes'
  end

  def is_nil_name? name
    name[/NIL\.?/i] ? true : false
  end

  AYES_TELLER = regexp('teller(s)? for t.*e ayes', 'i') unless defined? AYES_TELLER
  def is_ayes_teller? text
    AYES_TELLER.match(text.gsub("'",' ').squeeze(' ')) ? true : false
  end

  NOES_TELLER = regexp('teller(s)? for t.*e noes', 'i') unless defined? NOES_TELLER
  def is_noes_teller? text
    NOES_TELLER.match(text.gsub("'",' ').squeeze(' ')) ? true : false
  end

end
