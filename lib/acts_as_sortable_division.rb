module Acts

  module SortableDivision
    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      def acts_as_sortable_division(options={})
        include Acts::SortableDivision::InstanceMethods
      end
    end

    module InstanceMethods

      ALPHANUMERIC = /^.*?(([A-Z]){1,1}[A-Z0-9]{1,1}(?!\.).*)$/i

      def alphanumeric_section_title
        if match = ALPHANUMERIC.match(self.section_title)
          match[1].upcase
        end
      end

      def calculate_index_letter
        if match = ALPHANUMERIC.match(self.section_title)
          match[2]
        end
      end
      
    end
  end
end