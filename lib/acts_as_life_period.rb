module Acts

  module LifePeriod
    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      def acts_as_life_period(options={})
        include Acts::LifePeriod::InstanceMethods
      end
    end

    module InstanceMethods

      def first_possible_date
        date = (start_date || (person.date_of_birth if person) || FIRST_DATE)
      end

      def last_possible_date
        date = (end_date || (person.date_of_death if person) || LAST_DATE)
      end
      
    end
  end
end