module Acts

  module Mentionable
    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      def acts_as_mentionable(options)
        include Acts::Mentionable::InstanceMethods
        extend Acts::Mentionable::SingletonMethods
        cattr_accessor :resolver_class, :mention_class
        # cattr_accessor :inner_timing
        self.resolver_class = options[:resolver_class_name]
        self.mention_class = options[:mention_class_name]
        # self.inner_timing = 0
      end
    end

    module InstanceMethods

    end

    module SingletonMethods

      def resolver
        resolver_class.constantize
      end

      def find_mention_attributes text
        text ? resolver.new(text).mention_attributes : []
      end

      def populate_mentions(text, section, contribution)
        find_mention_attributes(text).collect do |attributes|
          create_mention(attributes, section, contribution)
        end
      end

      def create_mention(attributes, section, contribution)
        instance = find_or_create_from_resolved_attributes(attributes)
        mention_class.constantize.new(name.downcase.to_sym => instance,
                                      :contribution => contribution,
                                      :section => section,
                                      :sitting => section.sitting,
                                      :start_position => attributes[:start_position],
                                      :end_position => attributes[:end_position],
                                      :date => section.sitting.date)
      end

    end

  end
end