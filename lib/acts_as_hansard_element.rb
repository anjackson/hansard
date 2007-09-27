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

      def image_marker(options)
        images = find_images_in_text
        if !images.empty?
          options[:current_image_src] = images.last
        else
          if first_image_source and first_image_source != options[:current_image_src]
            # yield the marker so that it can be rendered
            options[:current_image_src] = first_image_source
            yield "image", first_image_source
          end
        end
      end

      def column_marker(options)
        text_cols = find_columns_in_text
        if !text_cols.empty?
          options[:current_column] = text_cols.last
        else
          if first_col and first_col != options[:current_column]
            # yield the marker so that it can be rendered
            options[:current_column] = first_col
            yield "column", first_col
          end
        end
      end

      def find_images_in_text
        images = []
        images = text.scan(/<image src="(.*?)"/) if respond_to? "text" and text
        images = images.map{ |i| i[0] }
      end

      def find_columns_in_text
        text_cols = []
        text_cols = text.scan(/<col>(\d+)/) if respond_to? "text" and text
        text_cols.map{ |c| c[0].to_i }
      end

    end

    module SingletonMethods
    end

  end

end