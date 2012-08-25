
class ActiveRecordModelProxy3
  include PresentOnDate
  acts_as_present_on_date [:start_date, :end_date],
      :url_helper_method => 'individual_path', :url_parameter => 'individual',
      :group_by_with_date => 'party_status',
      :sort_by => 'individual.fullname', :title => 'individual.fullname'

  def self.exists? params
    return params[:start_date] == START_DATE || params[:end_date] == END_DATE
  end
end
