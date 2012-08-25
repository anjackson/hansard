module ActiveRecord #:nodoc:
  module Serialization
    class Serializer #:nodoc:

      # Add associations specified via the <tt>:includes</tt> option.
      # Expects a block that takes as arguments:
      #   +association+ - name of the association
      #   +records+     - the association record(s) to be serialized
      #   +opts+        - options for the association records
      def add_includes(&block)
        if include_associations = options.delete(:include)
          base_only_or_except = { :except => options[:except],
                                  :only => options[:only] }

          include_has_options = include_associations.is_a?(Hash)
          associations = include_has_options ? include_associations.keys : Array(include_associations)

          for association in associations
            records = case @record.class.reflect_on_association(association).macro
            when :has_many, :has_and_belongs_to_many
              @record.send(association).to_a
            when :has_one, :belongs_to
              @record.send(association)
            end

            # Here is the change - if the associated object is of the same class as the main
            # object, it inherits the same :include 
            unless records.nil?
              sample_record = records.is_a?(Enumerable) ? records.first : records
              if sample_record and sample_record.class.base_class == @record.class.base_class
                association_options = include_has_options ? {:include => include_associations} : base_only_or_except
              else  
                association_options = include_has_options ? include_associations[association] : base_only_or_except
              end
              opts = options.merge(association_options)
              yield(association, records, opts)
            end
          end

          options[:include] = include_associations
        end
      end
    end
  end
end
