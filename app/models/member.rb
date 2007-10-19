class Member

  attr_accessor :name, :contribution_count

  def initialize(name, contribution_count)
    @name, @contribution_count = name, contribution_count
  end
end
