class DivisionPlaceholder < Contribution

  has_one :division, :foreign_key => 'division_placeholder_id', :dependent => :destroy
  acts_as_sortable_division

  def have_a_complete_division? divided_text
    if divided_text
      if false # division.votes.select {|v| v.is_a? NoeVote}.size == 4
        puts 'have_a_complete_division? ' +
          ' ayes' +
          division.votes.select {|v| v.is_a? AyeVote}.size.to_s +
          ' aye teller' +
          division.votes.select {|v| v.is_a? AyeTellerVote}.size.to_s +
          ' noe' +
          division.votes.select {|v| v.is_a? NoeVote}.size.to_s +
          ' noe teller' +
          division.votes.select {|v| v.is_a? NoeTellerVote}.size.to_s
        puts division.have_a_complete_division?(divided_text).to_s
      end

      division.have_a_complete_division? divided_text
    else
      false
    end
  end

  def division_name= text
    division.name = text if division
  end

  def result_text
    if next_contribution = following_contribution
      text = next_contribution.plain_text
      Division.is_a_division_result?(text) ? text : nil
    else
      nil
    end
  end

  def divided_text
    if divided_text = preceding_contribution
      divided_text.plain_text
    else
      nil
    end
  end

  def section_for_division
    if has_parent_section?
      section.parent_section
    else
      section
    end
  end

  def sub_section
    has_parent_section? ? section : nil
  end
  
  def has_parent_section?
    section.is_clause? && section.parent_section && !section.parent_section.title.blank?
  end

  def index_letter
    @index_letter ||= calculate_index_letter
  end

  def section_title
    section_for_division.title
  end

  def division_id
    division ? division.division_id : nil
  end

  def sub_section_title
    sub_section ? sub_section.title : nil
  end

  def vote_count
    division.vote_count
  end

  def to_xml(options={})
    division ? division.to_xml(options) : ''
  end

  def populate_mentions
    # overrides method to prevent act and bill matching in division table
  end
end
