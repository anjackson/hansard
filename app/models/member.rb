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
end
