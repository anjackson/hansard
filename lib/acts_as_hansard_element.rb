module Acts

  module HansardElement

    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    module ClassMethods

      def acts_as_hansard_element(options={})
        include Acts::HansardElement::InstanceMethods
        extend Acts::HansardElement::SingletonMethods
      end
    end

    module InstanceMethods

      def marker_xml(options)
        xml = options[:builder] ||= Builder::XmlMarkup.new
        markers(options) do |marker_type, marker_value|
          if marker_type == "image"
            xml.image(:src => marker_value)
          elsif marker_type == "column"
            xml.col(marker_value)
          end
        end
      end

      def markers(options)
        image_marker(options){ |marker_type, marker_value| yield marker_type, marker_value }
        column_marker(options){ |marker_type, marker_value| yield marker_type, marker_value }
      end

      def column_marker(options)
        if start_column and start_column != options[:current_column]
          # yield the marker so that it can be rendered
          options[:current_column] = start_column
          yield "column", start_column
        end
        if start_column and start_column != end_column
          options[:current_column] = end_column
        end
      end
      
      def image_marker(options)
        return unless respond_to? :start_image
        if start_image != options[:current_image]
          # yield the marker so that it can be rendered
          options[:current_image] = start_image
          yield "image", start_image
        end
        if start_image != end_image
          options[:current_image] = end_image
        end
      end
      
    end

    module SingletonMethods
    end

  end

end