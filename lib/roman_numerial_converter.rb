module Hansard
end
=begin
class Hansard::Roman

  IS_ROMAN = /^#{ ROMAN_MAP.keys.sort { |a, b| b <=> a }.inject("") do |exp, n|
    num = ROMAN_MAP[n]
    exp << if num.length == 2 then "(?:#{num})?" else num + "{0,3}" end
  end }$/i
  IS_ARABIC = /^(?:[123]\d{3}|[1-9]\d{0,2})$/

  if __FILE__ == $0
    ARGF.each_line() do |line|
      line.chomp!
      case line
      when IS_ROMAN  then puts ROMAN_NUMERALS.index(line) + 1
      when IS_ARABIC then puts ROMAN_NUMERALS[line.to_i - 1]
      else raise "Invalid input:  #{line}"
      end
    end
  end
end
=end
class String

  ROMAN_MAP = {               1 => "I",
                4 => "IV",    5 => "V",
                9 => "IX",   10 => "X",
               40 => "XL",   50 => "L",
               90 => "XC",  100 => "C",
              400 => "CD",  500 => "D",
              900 => "CM", 1000 => "M" }

  IS_ROMAN = /^#{ ROMAN_MAP.keys.sort { |a, b| b <=> a }.inject("") do |exp, n|
    num = ROMAN_MAP[n]
    exp << if num.length == 2 then "(?:#{num})?" else num + "{0,3}" end
  end }$/i

  IS_ARABIC = /^(?:[123]\d{3}|[1-9]\d{0,2})$/

  MAXIMUM_ROMAN_HANDLED = 3999
  ROMAN_NUMERALS = Array.new(MAXIMUM_ROMAN_HANDLED) do |index|
    target = index + 1
    ROMAN_MAP.keys.sort { |a, b| b <=> a }.inject("") do |roman, div|
      times, target = target.divmod(div)
      roman << ROMAN_MAP[div] * times
    end
  end

  def is_roman_numerial?
    IS_ROMAN.match(self) ? true : false
  end

  def is_arabic_numerial?
    IS_ARABIC.match(self) ? true : false
  end

  def roman_to_i
    if is_roman_numerial?
      if ROMAN_NUMERALS.include? self
        ROMAN_NUMERALS.index(self) + 1
      else
        raise "cannot convert to integer, '#{self}' larger than maximum number handled #{MAXIMUM_ROMAN_HANDLED}"
      end
    else
      raise "cannot convert to integer, '#{self}' is not a recognized roman numerial less than the maximum handled #{MAXIMUM_ROMAN_HANDLED + 1}"
    end
  end
end
