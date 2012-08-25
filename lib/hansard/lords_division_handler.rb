module Hansard
end

module Hansard::LordsDivisionHandler

  def start_of_division?(year, header_values, series_number=nil)
    LordsDivision.start_of_division?(year, header_values, series_number)
  end

  def continuation_of_division? year, values
    LordsDivision.continuation_of_division? year, values
  end

  LORDS_DIVIDED_PATTERN = regexp('contents\s(\d+)\snot(\s|-)content(s)?(\d+)?') unless defined? LORDS_DIVIDED_PATTERN
  def is_divided_text? text
    text = String.new text.downcase
    text.tr!(':,;."', ' ')
    text.squeeze!(' ')
    LORDS_DIVIDED_PATTERN.match(text.sub("'",' ').squeeze(' ')) ? true : false
  end

  def handle_vote text, division, vote_type
    parts = text.split('[')
    name = parts[0].strip

    log 'vote_type nil: ' + division.inspect unless vote_type
    vote = vote_type.new({
      :name => name,
      :column => @column
    })
    vote.division = division
    division.votes << vote
  end

  def is_contents? text
    LordsDivision.is_contents? text
  end

  def is_not_contents? text
    LordsDivision.is_not_contents? text
  end

  def handle_the_vote text, cell, division, last_column_cells, text_below=nil
    begin
      if LordsDivision.is_division_number? text
        # it's the division number, ignore

      elsif is_contents? text
        @vote_type = ContentVote

      elsif is_not_contents? text
        complete_remaining_votes division
        @vote_type = NotContentVote

      elsif text.downcase.include? 'teller'
        previous_vote_type = @vote_type
        if previous_vote_type == ContentVote
          @vote_type = ContentTellerVote
        elsif previous_vote_type == NotContentVote
          @vote_type = NotContentTellerVote
        end
        handle_vote text, division, @vote_type
        @vote_type = previous_vote_type
      else
        handle_vote text, division, @vote_type
      end
    rescue Exception => e
      raise Hansard::DivisionParsingException, e.to_s
    end
  end

  def obtain_division year, header_values, node, section=nil
    if start_of_division?(year, header_values)
      division_name = LordsDivision.name_from(header_values.first)
      return new_division(division_name), is_new = true

    elsif continuation_of_division?(year, header_values)
      existing_division = last_division_on_division_stack

      if existing_division
        return existing_division, is_new = false
      else
        log 'Could not find beginning of division for: ' + node.to_s
        unparsed_divison = handle_unparsed_division node, section
        return unparsed_divison, is_new = false
      end

    elsif header_values.size == 1 && is_divided_text?(header_values.first)
      divided_contribution = create_house_divided_contribution header_values.first
      add_division_after_divided_text section, divided_contribution
      header_values=(node/'table[1]/tr[2]/td').collect {|td| td.to_plain_text}
      return obtain_division(year, header_values, node, section)

    else
      raise Hansard::DivisionParsingException, 'Unexpected table in Division: ' + node.to_s[0..150]
    end
  end

  def new_division division_name
    division = LordsDivision.new({
      :name => division_name,
      :time_text => nil
    })
  end
end
