module PeopleHelper
  
  def alternative_name_details(alternative_name)
    text = "#{alternative_name.name} "
    text += dates_or_unknown(alternative_name)
  end
  
  def birth_and_death_dates(person)
    dates = ''
    if person.date_of_birth
      if person.estimated_date_of_birth
        dates += person.date_of_birth.year.to_s
      else
        dates += person.date_of_birth.to_s(:long) 
      end
    end
    dates += ' - '
    if person.date_of_death
      if person.estimated_date_of_death
        dates += person.date_of_death.year.to_s
      else
        dates += person.date_of_death.to_s(:long) 
      end
    end
    dates
  end

end