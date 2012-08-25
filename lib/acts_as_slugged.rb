
module Acts

  module Slugged

    MAX_SLUG_LENGTH = 40

    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    def self.normalize_text text
      decoded_text = HTMLEntities.new.decode(text)
      begin
        ascii_text = Iconv.new('US-ASCII//TRANSLIT', 'UTF-8').iconv(decoded_text)
      rescue
        begin
          ascii_text = Iconv.new('US-ASCII//TRANSLIT', 'ISO-8859-1').iconv(decoded_text)
        rescue
          ascii_text = Iconv.new('US-ASCII//IGNORE', 'UTF-8').iconv(decoded_text)
        end
      end
      ascii_text.downcase!
      ascii_text.gsub!(/[^a-z0-9\s_-]+/, '')
      ascii_text.gsub!(/[\s_-]+/, '-')
      ascii_text
    end

    module ClassMethods

      def acts_as_slugged(options={})
        cattr_accessor :slug_field
        self.slug_field = options[:field] || :name
        include Acts::Slugged::InstanceMethods
        extend Acts::Slugged::SingletonMethods
      end
    end

    module InstanceMethods

      def to_param
        slug
      end

      def recalculate_slug
        old_slug = String.new slug
        populate_slug :force => true
        save! if old_slug != slug
      end

      protected
        # strip or convert anything except letters, numbers and dashes
        # to produce a string in the format 'this-is-a-slugcase-string'
        # and convert html entities to unicode
        def normalize_text text
          Slugged.normalize_text text
        end

        def populate_slug options={}
          if slug.nil? || (options[:force] == true)
            self.slug = make_slug(self.send(slug_field), :truncate => false) do |candidate_slug|
              match = self.class.find_by_slug(candidate_slug)
              if match && self.id
                duplicate_found = match.id != self.id
              else
                duplicate_found = match ? true : false
              end
              duplicate_found
            end
          end
        end

        def slug_start_index(slug)
          1
        end

        def make_slug text, options={}
          options[:truncate] = true unless options.has_key?(:truncate)
          base_slug = normalize_text(text)
          base_slug = truncate_slug(base_slug) if options[:truncate]
          index = slug_start_index(base_slug)
          candidate_slug = base_slug
          while slug_exists = (yield candidate_slug)
            candidate_slug = "#{base_slug}-#{index}"
            index += 1
          end
          candidate_slug.chomp('-')
        end

        def truncate_slug(string)
          cropped_string = truncate_text(string, MAX_SLUG_LENGTH+1, "")
          if string != cropped_string
            if cropped_string[0..-1] == "-"
              cropped_string = truncate_text(cropped_string, MAX_SLUG_LENGTH, "")
            else
              #  back to the last complete word
              last_wordbreak = cropped_string.rindex('-')
              if !last_wordbreak.nil?
                cropped_string = truncate_text(cropped_string, last_wordbreak, "")
              else
                cropped_string = truncate_text(cropped_string, MAX_SLUG_LENGTH, "")
              end
            end
          end
        cropped_string
      end

      def truncate_text(text, length = 30, truncate_string = "...")
        if text.nil? then return end
        l = length - truncate_string.chars.length
        (text.chars.length > length ? text.chars[0...l] + truncate_string : text).to_s
      end
    end

    module SingletonMethods
      def normalize_text text
        Slugged.normalize_text text
      end
    end
  end
end
