class TimeResolver

  NOT_TIME_PATTERN = regexp('\d\.\]')
  NOT_TIME_PATTERN2 = regexp('(Division|See|Teller|No|President|col)')
  
  def initialize text
    if NOT_TIME_PATTERN.match(text) || NOT_TIME_PATTERN2.match(text)
      @time = nil
    else
      begin
        text = text.downcase.chars
        text.tr!(']', '')
        text.tr!(',', '.')
        text.sub!('midnight', 'am')
        text.sub!(/^\./, '')
        text.sub!(/\.(\d)\./, '.\1 ')
        text.squeeze!(' ')
        text.gsub!('. ', '.')
        text.sub!(/(\d\d)\s(\d\d)/, '\1:\2')
        text.sub!(/(\d)\.(\d)/, '\1:\2')
        text.sub!(/(a|p)\sm/, '\1m')
        text.sub!(/\sm/, 'am')
        text.tr!('.', '')
        text.sub!(/m\d+/,'m')
        @time = Time.parse(text.to_s)
        @time
      rescue Exception
        @time = nil
      end
    end
  end

  def is_time?
    @time ? true : false
  end

  def time
    @time
  end
end
