class Date

  def decade
    ((year/10)*10)
  end
  
  def Date.year_from_century_string century_string
    century_to_year(century_string[1..2].to_i)
  end

  def Date.first_of_century(century)
     Date.new(century_to_year(century))
  end
  
  def Date.century_to_year(century)
    ((century - 1).to_s + "00").to_i
  end
  
end

def zero_padded_digit(digit)
  digit < 10 ? "0"+ digit.to_s : digit.to_s
end