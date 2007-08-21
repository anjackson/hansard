require 'enumerator'

class Division < ActiveRecord::Base

  belongs_to :division_placeholder, :class_name => 'DivisionPlaceholder', :foreign_key => 'division_placeholder_id'
  has_many :votes
  has_many :aye_votes, :class_name => "Vote", :conditions => "type = 'AyeVote'"
  has_many :noe_votes, :class_name => "Vote", :conditions => "type = 'NoeVote'"
  
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
        votes_xml(:votes => aye_votes, :builder => xml, :vote_type => "AYES")
        votes_xml(:votes => noe_votes, :builder => xml, :vote_type => "NOES")        
      end
    end
  end
  
  def votes_xml(options)
    votes = options[:votes]
    xml = options[:builder]
    xml.tr do
      xml.td(:align => "center", :colspan => "2") do
        xml.b(options[:vote_type]) 
      end
    end
    votes.each_slice(2) do |slice|
      xml.tr do 
        xml.td do 
          slice[0].to_xml(options)
        end
        xml.td do
          slice[1].to_xml(options) if slice.size > 1
        end
      end
    end
  end
  
end
