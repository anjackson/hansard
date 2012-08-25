class UnparsedDivisionPlaceholder < DivisionPlaceholder

  def divided_text
    nil
  end

  def number
    '?'
  end

  def house
    sitting.house
  end

  def compare_by_division_number division
    if division.is_a? Division
      division.division_placeholder.object_id <=> object_id
    else
      division.object_id <=> object_id
    end
  end
end
