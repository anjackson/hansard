class Doctype < ActiveRecord::Base
  set_table_name "DM_DOC_TYPES"
  set_primary_key :Id
  has_many :stages, :foreign_key => "DocTypeId", :order => "Stage"
  
end
