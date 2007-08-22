require 'enumerator'

class Division < ActiveRecord::Base

  belongs_to :division_placeholder, :class_name => 'DivisionPlaceholder', :foreign_key => 'division_placeholder_id'
  has_many :votes
  has_many :aye_votes, :class_name => "Vote", :conditions => "type = 'AyeVote'"
  has_many :noe_votes, :class_name => "Vote", :conditions => "type = 'NoeVote'"
  has_many :aye_teller_votes, :class_name => "Vote", :conditions => "type = 'AyeTellerVote'"
  has_many :noe_teller_votes, :class_name => "Vote", :conditions => "type = 'NoeTellerVote'"
  
  alias :to_activerecord_xml :to_xml

  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new
    xml.division do
      xml.table do
        xml.tr do
          xml.td do 
            xml.b do
              xml << name
            end
          end
          xml.td(:align => "right") do 
            xml.b do
              xml << time_text
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
  
  def votes_header_xml(options)
    xml = options[:builder] ||= Builder::XmlMarkup.new
    xml.tr do
      xml.td(:align => "center", :colspan => "2") do
        xml.b(options[:vote_type]) 
      end
    end
  end
  
  def vote_pair_xml(options)
    xml = options[:builder] ||= Builder::XmlMarkup.new
    first_vote = options[:first_vote]
    second_vote = options[:second_vote]
    if first_vote and first_vote.first_col != options[:current_column]
      xml << "</table>"
      first_vote.marker_xml(options)
      xml << "<table>"
    end
    xml.tr do 
      xml.td do 
        first_vote.to_xml(options) if first_vote
      end
      xml.td do
        second_vote.to_xml(options) if second_vote
      end
    end
  end
  
  def votes_xml(options)

    votes = options[:votes]
    teller_votes = options[:teller_votes]
    xml = options[:builder]
    
    votes_header_xml(options)
    
    if teller_votes.empty? 
      simple_votes = votes
    else
      teller_rows = teller_votes.size + 2
      simple_vote_limit = votes.size - teller_rows
      simple_votes = votes[0...simple_vote_limit]
    end
    
    simple_votes.each_slice(2) do |slice|
      options[:first_vote] = slice.shift
      options[:second_vote] = slice.shift
      vote_pair_xml(options)
    end
    
    if !teller_votes.empty?
      leftover_votes = votes[simple_vote_limit..votes.size] || []
      
      xml.tr do
        xml.td do
          leftover_votes.shift.to_xml(options) if !leftover_votes.empty?
        end
        xml.td do 
          xml << "Tellers for the #{options[:vote_type].titleize}:"
        end
      end
    
      while (!teller_votes.empty? or !leftover_votes.empty?)
        options[:first_vote] = teller_votes.shift
        options[:second_vote] = leftover_votes.shift
        vote_pair_xml(options)
      end
    end
    
  end

end
