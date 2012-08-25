module Acts

  module DuplicateRetryer

    def self.included(base) # :nodoc:
      base.extend ClassMethods
      base.class_eval do
        class << self
          alias_method_chain :create, :refind
        end
      end
      
    end

    module ClassMethods

      MAXIMUM_RETRIES_ON_DUPLICATE = 1
      
      def acts_as_duplicate_retryer(options={})
       cattr_accessor :unique_fields, :query
       self.unique_fields = options[:unique_fields] || [:slug]
       query_parts = self.unique_fields.map{ |field_name| "#{field_name.to_s} = ?" }
       self.query = query_parts.join(" AND ")
      end
      
      def create_with_refind(attributes, &block)
        retry_count = 0
        begin 
          return create_without_refind(attributes, &block)
        rescue ActiveRecord::StatementInvalid => error
          raise if retry_count >= MAXIMUM_RETRIES_ON_DUPLICATE
          retry_count += 1
          logger.info "Duplicate detected on retry #{retry_count}, trying to return existing record"
          query_params = [self.query]
          self.unique_fields.each do |field_name|
            query_params << attributes[field_name]
          end
          if error.to_s.include?('Duplicate entry')
            instance_in_db = find(:first, :conditions => query_params) 
            return instance_in_db if instance_in_db
            raise error
          end
          raise error
        end
      end

    end

  end
end