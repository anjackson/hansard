class Member < ActiveRecord::Base

  before_validation_on_create :populate_slug
  validates_uniqueness_of :slug, :name

  acts_as_slugged

  has_many :contributions

  def self.find_or_create_from_name name
    member = Member.find_by_name(name)
    unless member
      member = Member.create!(:name => name)
    end
    member
  end

  def self.find_all_members
    Member.find(:all).sort_by(&:name)
  end

  def self.find_member slug
    Member.find_by_slug(slug)
  end

  def contribution_count
    contributions.size
  end

  def contributions_in_groups_by_year_and_section
    by_section = contributions.sort_by{|c| c.section_id}.in_groups_by {|c| c.section_id}
    by_section.sort_by{|s| s.first.date}.in_groups_by {|s| s.first.year}
  end

  protected

    def populate_slug
      unless slug
        self.slug = make_slug(name, :truncate => false) do |candidate_slug|
          duplicate_found = Member.find_by_slug(candidate_slug) ? true : false
          duplicate_found
        end
      end
    end

end
