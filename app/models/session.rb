class Session < ActiveRecord::Base

  has_many :sittings, :foreign_key => 'session_id', :dependent => :destroy
  belongs_to :source_file

  alias :to_activerecord_xml :to_xml
  acts_as_hansard_element

end
