require 'enumerator'

class LordsDivision < Division

  has_many :content_votes,     :class_name => "Vote", :conditions => "type = 'ContentVote'",    :foreign_key => 'division_id'
  has_many :not_content_votes, :class_name => "Vote", :conditions => "type = 'NotContentVote'", :foreign_key => 'division_id'

  has_many :content_teller_votes,     :class_name => "Vote", :conditions => "type = 'ContentTellerVote'",    :foreign_key => 'division_id'
  has_many :not_content_teller_votes, :class_name => "Vote", :conditions => "type = 'NotContentTellerVote'", :foreign_key => 'division_id'

  DIVISION_TITLE = regexp('^divisi?i?on', 'i')

  CONTENTS_PATTERN = 'conten?ts?'
  NOT_CONTENTS_PATTERN = 'no(t|n)(-| )'+CONTENTS_PATTERN

  CONTENTS = regexp(CONTENTS_PATTERN, 'i')
  NOT_CONTENTS = regexp(NOT_CONTENTS_PATTERN, 'i')

  CONTENTS_NOT_CONTENTS = regexp(CONTENTS_PATTERN+'\s(\d+)\s'+NOT_CONTENTS_PATTERN+'\s(\d+)', 'i')

  class << self
    def start_of_division? year, values, series_number=nil
      if values.size == 1
        heading = values.first
        if is_division_number?(heading) || is_contents?(heading)
          true
        else
          false
        end
      else
        false
      end
    end

    def is_division_number? text
      DIVISION_TITLE.match(text) ? true : false
    end

    def is_contents? text
      (CONTENTS.match(text) && NOT_CONTENTS.match(text).nil? ) ? true : false
    end

    def is_not_contents? text
      NOT_CONTENTS.match(text) ? true : false
    end

    def name_from text
      number = Division.number_from(text)
      if number
        "Division No. #{number}"
      else
        DIVISION_TITLE.match(text) ? text : nil
      end
    end

    def continuation_of_division? year, values
      if !start_of_division?(year, values)
        if pre_1981_and_three_columns(year, values) ||
            post_1980_and_two_columns(year, values) ||
            (values.size == 1 && NOT_CONTENTS.match(values.first) )
          true
        else
          false
        end
      else
        false
      end
    end

    def vote_count divided_text
      divided_text = String.new divided_text
      divided_text.tr!(':,;."', ' ')
      divided_text.squeeze!(' ')
      if (match = CONTENTS_NOT_CONTENTS.match divided_text)
        match[1].to_i + match[4].to_i
      else
        0
      end
    end
  end

  def have_a_complete_division? divided_text
    last_division_count = vote_count
    divided_count = self.class.vote_count(divided_text)
    have_a_complete_division = (last_division_count == divided_count)

    unless have_a_complete_division
      within_four_votes = (last_division_count - divided_count).abs <= 4
      two_tellers_each_side = (content_tellers.size == 2) && (not_content_tellers.size == 2)
      have_a_complete_division = (within_four_votes && two_tellers_each_side)

      if false
        puts divided_text
        puts "Table, content_count: #{contents.size} not_content_count: #{not_contents.size} "
        puts "Divided text count: #{divided_count}"
        puts "last_division_count: #{last_division_count}"
        puts "content_teller_count: #{content_tellers.size} content tellers: #{ content_tellers.collect(&:name).join(', ') }"
        puts "not_content_teller_count: #{not_content_tellers.size} not content tellers: #{ not_content_tellers.collect(&:name).join(', ') }"
        puts "within_four_votes: #{within_four_votes}"
        puts "two_tellers_each_side: #{two_tellers_each_side}"
        puts "have_a_complete_division: #{have_a_complete_division}"
        puts ''
      end
    end
    have_a_complete_division
  end

  def house
    'Lords'
  end

  def content_tellers
    votes.select{ |v| v.is_a? ContentTellerVote }
  end

  def not_content_tellers
    votes.select{ |v| v.is_a? NotContentTellerVote }
  end

  def contents
    votes.select{ |v| v.is_a? ContentVote }
  end

  def not_contents
    votes.select{ |v| v.is_a? NotContentVote }
  end

  def content_vote_names teller_label=nil
    contents.collect do |v|
      name = v.name
      name += teller_label if v.is_a?(ContentTellerVote) && teller_label
      name
    end.sort {|a,b|a.downcase<=>b.downcase}
  end

  def not_content_vote_names teller_label=nil
    not_contents.collect do |v|
      name = v.name
      name += teller_label if v.is_a?(NotContentTellerVote) && teller_label
      name
    end.sort {|a,b|a.downcase<=>b.downcase}
  end

  def vote_count
    votes.size
  end

  def to_csv url=nil
    text = [super]
    text << "\n# Contents"
    text << content_vote_names(', [Teller]').collect{|name| %Q|"#{name}"|.sub(', [Teller]"','", [Teller]')}
    text << "\n# Not-Contents"
    text << not_content_vote_names(', [Teller]').collect{|name| %Q|"#{name}"|.sub(', [Teller]"','", [Teller]')}
    text.flatten.join("\n")
  end

end
