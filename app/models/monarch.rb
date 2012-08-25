class Monarch

  attr_reader :name

  class << self
    def find_all
      list.collect do |name|
        Monarch.new name
      end
    end

    def list
      ['GEORGE III','GEORGE IV','WILLIAM IV','VICTORIA','EDWARD VII','GEORGE V','EDWARD VIII','GEORGE VI','ELIZABETH II']
    end

    def params
      /#{Regexp.union( *list.map{|name| slug(name)} )}/
    end

    def volumes_by_monarch
      @volumes_by_monarch ||= create_volumes_by_monarch
    end

    def create_volumes_by_monarch
      by_monarch = {}
      list.each do |monarch|
        by_monarch[monarch] = (Volume.find_by_monarch(monarch) ? true : false)
      end
      by_monarch
    end

    def monarch_name(monarch)
      parts = []
      monarch.each(' ') do |part|
        if part.is_roman_numeral?
          parts << part
        else
          parts << part.titleize
        end
      end
      parts.join(' ').squeeze(' ')
    end

    def slug(monarch)
      monarch.downcase.gsub(' ','-')
    end

    def slug_to_name(slug)
      name = slug.gsub('-', ' ').upcase
    end
  end

  def initialize name
    @name = name
  end

  def slug
    Monarch.slug(name)
  end
end