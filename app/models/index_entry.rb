class IndexEntry < ActiveRecord::Base
  belongs_to :index
  belongs_to :parent_entry, :class_name => "IndexEntry", :foreign_key => 'parent_entry_id'
end