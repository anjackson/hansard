class ConstituencyAlias < ActiveRecord::Base
  validates_uniqueness_of :alias
  belongs_to :constituency
end