class Index < ActiveRecord::Base
  has_many :index_entries, :dependent => :destroy
end