class Stage < ActiveRecord::Base
  set_table_name "DM_STAGES"
  set_primary_key :Id
  belongs_to :doctype, :foreign_key => "DocTypeId"
end
