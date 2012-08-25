module Acts

  module Membership
    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end
    
  
    module ClassMethods
      def acts_as_membership(options={})
        include Acts::Membership::InstanceMethods
        extend Acts::Membership::SingletonMethods
      end
    end

    module InstanceMethods

    end

    module SingletonMethods
      
      def hash_of_lists
        Hash.new { |hash, key| hash[key] = [] }
      end
      
      def list_hash(keys)
        hash = {}
        keys.each { |key| hash[key] = hash_of_lists }
        hash
      end
      
      def membership_lookups(date)
        membership_lookups = list_hash(lookup_hash_keys)
        members_on_date(date).each{ |member| add_membership_to_lookups(member, membership_lookups, date) }
        membership_lookups
      end
      
      def add_fullname_to_lookups(member, hashes)
        add_name_versions(member, member.person, hashes)
      end
      
      def add_offices_to_lookups(member, hashes, date)
        member.person.office_holders.each do |office_holder|
          if office_holder.start_date and office_holder.start_date <= date and (!office_holder.end_date or office_holder.end_date >= date)
            office_key = office_holder.office.name.downcase
            hashes[:office_names][office_key] << member.id
          end
        end
      end
      
      def add_name_versions(member, name, hashes)
        lastname = name.lastname.gsub('-', ' ')
        fullname_key = "#{name.firstname} #{lastname}".downcase 
        lastname_key = lastname.downcase 
        hashes[:lastnames][lastname_key] << member.id
        return if name.firstname.blank?
        return unless hashes.has_key? :fullnames
        hashes[:fullnames][fullname_key] << member.id
        return unless hashes.has_key? :initial_and_lastnames
        initial_and_lastname_key = "#{name.firstname.first} #{lastname}".downcase 
        hashes[:initial_and_lastnames][initial_and_lastname_key] << member.id
      end
      
      def add_alternative_names_to_lookups(member, hashes, date)
        member.person.alternative_names.each do |name|
          if name.first_possible_date <= date and name.last_possible_date >= date
            add_name_versions(member, name, hashes)
          end
        end
      end
      
      def add_alternative_titles_to_lookups(member, hashes, date)
        member.person.alternative_titles.each do |title|
          if title.first_possible_date <= date and title.last_possible_date >= date
            add_title_to_lookups(title, hashes, member)
          end
        end
      end
      
      def add_constituency_to_lookups(member, hashes)
        return unless hashes.has_key? :constituency_ids
        hashes[:constituency_ids][member.constituency_id] << member.id
      end
      
      def add_title_to_lookups(title, hashes, member)
        return unless hashes.has_key? :place_titles
        return unless hashes.has_key? :titles
        return unless member.respond_to? :degree_and_title
        versions = [title.degree_and_title]
        versions << title.class.title_without_number(title.name) if !title.name.blank?
        versions.each do |version|
          place = title.class.find_title_place(version)
          if place
            add_to_list(hashes[:place_titles][version.downcase], member.id)
            title_without_place = title.class.title_without_place(version)
            add_to_list(hashes[:titles][title_without_place.downcase], member.id) if title_without_place
          else
            add_to_list(hashes[:titles][version.downcase], member.id)
          end
        end
      end
      
      def add_to_list(list, value)
        list << value unless list.include? value
      end
    
      def add_membership_to_lookups(member, hashes, date)
        add_fullname_to_lookups(member, hashes)
        add_constituency_to_lookups(member, hashes) 
        add_alternative_names_to_lookups(member, hashes, date)
        add_offices_to_lookups(member, hashes, date)
        add_title_to_lookups(member, hashes, member)
        add_alternative_titles_to_lookups(member, hashes, date)
      end
    
    end

  end
end