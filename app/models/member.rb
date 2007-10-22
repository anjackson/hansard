class Member

  attr_accessor :name, :contribution_count, :slug

  include Acts::Slugged::InstanceMethods

  def initialize(name, contribution_count)
    @name, @contribution_count = name, contribution_count
    @slug = make_slug(name, :truncate => false) {|candidate_slug| duplicate_found = false}
  end

  def self.find_all_members
    MemberContribution.find_all_members
  end

  def self.find_member slug
    members = MemberContribution.find_all_members
    members.select{|m| m.slug == slug}.first
  end

  def contributions_in_groups_by_year
    contributions.sort_by{|c| c.date}.in_groups_by {|c| c.year}
  end

  def contributions
    MemberContribution.find_all_by_member(self.name)
  end
end
