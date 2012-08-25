require 'enumerator'

class CommonsDivision < Division

  has_many :aye_votes, :class_name => "Vote", :conditions => "type = 'AyeVote'", :foreign_key => 'division_id'
  has_many :noe_votes, :class_name => "Vote", :conditions => "type = 'NoeVote'", :foreign_key => 'division_id'

  has_many :aye_teller_votes, :class_name => "Vote", :conditions => "type = 'AyeTellerVote'", :foreign_key => 'division_id'
  has_many :noe_teller_votes, :class_name => "Vote", :conditions => "type = 'NoeTellerVote'", :foreign_key => 'division_id'

  DIVISION_TITLE = regexp '^\[?Divisi?on'
  LIST_OF_AYES_OR_NOES = regexp '^List of the ?(AYES|NOES)\.?', 'i'

  def self.start_of_division? year, values, series_number=nil
    if values.first && DIVISION_TITLE.match(values.first)
      if pre_1981_and_three_columns(year, values) || post_1980_and_two_columns(year, values)
        true
      else
        false
      end
    elsif values.first && values.first.strip.chomp('.') == 'AYES'
      true
    elsif series_number == 3 && values.first && LIST_OF_AYES_OR_NOES.match(values.first)
      true
    else
      false
    end
  end

  def self.continuation_of_division? year, values
    if !start_of_division?(year, values)
      if pre_1981_and_three_columns(year, values) ||
          post_1980_and_two_columns(year, values) ||
          (values.size == 1 && values.first.starts_with?('NOES') )
        true
      else
        false
      end
    else
      false
    end
  end

  AYES_NOES = regexp('ayes?\s(\d+)\snoes\s(\d+)')

  def self.vote_count divided_text
    divided_text = String.new divided_text.downcase
    divided_text.tr!(':,;.', ' ')
    divided_text.squeeze!(' ')
    if (match = AYES_NOES.match divided_text)
      match[1].to_i + match[2].to_i
    else
      0
    end
  end

  def have_a_complete_division? divided_text
    last_division_count = vote_count
    divided_count = self.class.vote_count(divided_text)
    have_a_complete_division = (last_division_count == divided_count)
    unless have_a_complete_division
      within_two_votes = (last_division_count - divided_count).abs <= 2
      two_tellers_each_side = (aye_teller_count == 2) && (noe_teller_count == 2)
      have_a_complete_division = (within_two_votes && two_tellers_each_side)

      if false
        puts divided_text
        puts "aye_teller_count: #{aye_teller_count} aye tellers: #{votes.select{|v| v.is_a? AyeTellerVote}.collect(&:name).join(', ') }"
        puts "noe_teller_count: #{noe_teller_count} noe tellers: #{votes.select{|v| v.is_a? NoeTellerVote}.collect(&:name).join(', ') }"
        puts "last_division_count: #{last_division_count}"
        puts "divided_text_count: #{divided_count}"
        puts "within_two_votes: #{within_two_votes}"
        puts "two_tellers_each_side: #{two_tellers_each_side}"
        puts "have_a_complete_division: #{have_a_complete_division}"
      end
    end
    have_a_complete_division
  end

  def house
    'Commons'
  end

  def vote_count
    votes.size - (aye_teller_count + noe_teller_count)
  end

  def aye_vote_names
    aye_votes.collect(&:name).sort {|a,b|a.downcase<=>b.downcase}
  end

  def noe_vote_names
    noe_votes.collect(&:name).sort {|a,b|a.downcase<=>b.downcase}
  end

  def aye_teller_names
    aye_teller_votes.collect(&:name).sort {|a,b|a.downcase<=>b.downcase}
  end

  def noe_teller_names
    noe_teller_votes.collect(&:name).sort {|a,b|a.downcase<=>b.downcase}
  end

  def aye_teller_count
    votes.select{|v| v.is_a? AyeTellerVote}.size
  end

  def noe_teller_count
    votes.select{|v| v.is_a? NoeTellerVote}.size
  end

  def to_csv url=nil
    text = [super]
    text << "\n# Ayes"
    text << aye_vote_names.collect{|name| %Q|"#{name}"|}
    text << "\n# Tellers for the Ayes"
    text << aye_teller_names.collect{|name| %Q|"#{name}"|}
    text << "\n# Noes"
    text << noe_vote_names.collect{|name| %Q|"#{name}"|}
    text << "\n# Tellers for the Noes"
    text << noe_teller_names.collect{|name| %Q|"#{name}"|}
    text.flatten.join("\n")
  end

  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new
    xml.division do
      xml.table do
        xml.tr do
          xml.td do
            xml.b do
              xml << name.to_xs if name?
            end
          end
          xml.td(:align => "right") do
            xml.b do
              xml << time_text.to_xs if time_text?
            end
          end
        end
        votes_xml(options.update(:votes => aye_votes,
                                 :teller_votes => aye_teller_votes,
                                 :vote_type => "AYES"))
        votes_xml(options.update(:votes => noe_votes,
                                 :teller_votes => noe_teller_votes,
                                 :vote_type => "NOES"))
      end
    end
  end

end
