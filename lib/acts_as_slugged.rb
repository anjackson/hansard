module Acts

  module Slugged

    MAX_SLUG_LENGTH = 40

    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    module ClassMethods

      def acts_as_slugged(options={})
        include Acts::Slugged::InstanceMethods
        extend Acts::Slugged::SingletonMethods
      end
    end

    module InstanceMethods

      protected
        # strip or convert anything except letters, numbers and dashes
        # to produce a string in the format 'this-is-a-slugcase-string'
        # and convert html entities to unicode
        def normalize_text text
          decoded_text = HTMLEntities.new.decode(text)
          ascii_text = Iconv.new('US-ASCII//TRANSLIT', 'UTF-8').iconv(decoded_text)
          ascii_text.downcase!
          ascii_text.gsub!(/[^a-z0-9\s_-]+/, '')
          ascii_text.gsub!(/[\s_-]+/, '-')
          ascii_text
        end

        def make_slug text
          base_slug = truncate_slug(normalize_text(text))
          index = 1
          candidate_slug = base_slug
          while slug_exists = (yield candidate_slug)
            candidate_slug = "#{base_slug}-#{index}"
            index += 1
          end
          candidate_slug
        end

        def truncate_slug(string)
          cropped_string = truncate(string, MAX_SLUG_LENGTH+1, "")
          if string != cropped_string
            if cropped_string[0..-1] == "-"
              cropped_string = truncate(cropped_string, MAX_SLUG_LENGTH, "")
            else
              #  back to the last complete word
              last_wordbreak = cropped_string.rindex('-')
              if !last_wordbreak.nil?
                cropped_string = truncate(cropped_string, last_wordbreak, "")
              else
                cropped_string = truncate(cropped_string, MAX_SLUG_LENGTH, "")
              end
            end
          end
        cropped_string
      end
    end

    module SingletonMethods
    end
  end
end
