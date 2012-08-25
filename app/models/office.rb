class Office < ActiveRecord::Base

  before_validation_on_create :populate_slug
  has_many :office_holders, :order => "start_date asc", :dependent => :destroy
  acts_as_slugged
  acts_as_string_normalizer
  acts_as_duplicate_retryer
  acts_as_id_finder

  ONE_HOLDER_OFFICES = ['Prime Minister',
                        'Attorney-General',
                        'Deputy Prime Minister',
                        'Solicitor-General',
                        'Lord Chancellor']

  class << self

    def find_all_sorted
      find(:all, :order => "name asc")
    end

    def find_office slug
      find_by_slug(slug)
    end

    def one_holder? name
      office = find_from_name(name)
      return false unless office
      if ONE_HOLDER_OFFICES.include? office.name
        return true
      else
        return false
      end
    end

    def find_or_create_from_name name
      name = corrected_name name
      office = find_by_name(name)
      office = create(:name => name) unless office
      office
    end

    def find_partial_matches(partial, limit=5)
      find_options = {  :conditions => [ "LOWER(name) LIKE ?", '%' + partial.downcase + '%' ],
                        :order => "name ASC",
                        :limit => limit }
      find(:all, find_options)
    end

    def find_by_name name
      find(:first, :conditions => ["LOWER(name) = ?", name.downcase])
    end

    def find_from_name name
      name = corrected_name(name)
      find_by_name(name)
    end

    def any_unconfirmed? office_list
      office_list.any?{ |holder| ! holder.confirmed? }
    end
  end

  def people_by_date
    office_holders.sort_by(&:first_possible_date).select{ |holder| holder.person }
  end

  def office_holder_count
    office_holders.size
  end

  def id_hash
    { :name => slug }
  end

  protected

    def Office.corrected_name name
      name = String.new(name)
      name.sub!('Tim MINISTER', 'The MINISTER')
      name = correct_spaced_hyphens(name)
      name = correct_hyphen_variants(name)
      name = correct_trailing_punctuation(name)
      name = correct_leading_punctuation(name)
      name = correct_bad_punctuation(name)
      name = correct_zeros_in_text(name)
      name = correct_common_word_variants(name)
      name = correct_malformed_offices(name)
      name = correct_leading_article(name)
      name.strip
    end
end