class String

  ORDINAL_PATTERN = /^(\d+)(st|nd|rd|th)$/
  SINGLE_DIGIT_ORDINALS = %w[first second third fourth fifth sixth seventh eigth ninth]
  DOUBLE_DIGIT_ORDINALS = %w[eleventh twelfth thirteenth fourteenth fifteenth sixteenth seventeenth eighteenth nineteenth]
  DECADE_ORDINALS = %w[tenth twentieth thirtieth fortieth fiftieth sixtieth seventieth eightieth ninetieth]
  DECADE_SIGNIFIER = %w[twenty thirty forty fifty sixty seventy eighty ninety]

  def ordinal_to_number
    ordinal = self.downcase.sub('-','').strip
    value = nil

    if (match = ORDINAL_PATTERN.match ordinal)
      value = match[1].to_i
    elsif (index = SINGLE_DIGIT_ORDINALS.index(ordinal))
      value = index + 1
    elsif (index = DECADE_ORDINALS.index(ordinal))
      value = 10 * (index + 1)
    else
      DECADE_SIGNIFIER.each_with_index do |decade, index|
        if ordinal.starts_with? decade
          value = (index+2)*10
          remainder = ordinal.sub(decade,'').ordinal_to_number
          if remainder
            value += remainder
          end
        end
      end
    end

    value
  end

end
