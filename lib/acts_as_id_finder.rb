module Acts

  module IdFinder

    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      def acts_as_id_finder(options={})
        extend Acts::IdFinder::SingletonMethods
      end
    end
    
    module SingletonMethods
          
      def id_attributes
        column_names.select{ |name| name.split('_').last == 'id' }
      end
    
    end
  end
end