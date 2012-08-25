module VolumesHelper

  def series_title(series_string, series_list)
    return series_list.first.name if series_list.size == 1
    return Series.series_name(series_string.to_i)
  end

  def format_percent quantity
    percent = "<span class='percent'>%</span>"
    if quantity == 0
      'none'
    elsif quantity < 1
      "less than 1#{percent}"
    else
      "#{quantity.round.to_s}#{percent}"
    end
  end
  
  def volume_title(series, volume_number, part)
    "#{series.name}, #{Volume.volume_name(volume_number, part.to_i)}"
  end

  def series_link(series)
    return series.name if series.volumes.empty?
    link_to(series.name, series_index_url(series.id_hash))
  end

  def volume_link(volume)
    link_content = ''
    link_content += volume.name
    return link_to(link_content, volume_url(volume.id_hash))
  end

  def regnal_years_text(volume)
    text = "#{volume.first_regnal_year}"
    text += "-#{volume.last_regnal_year}" if volume.first_regnal_year != volume.last_regnal_year
    text += " (#{volume.house.titleize})" if volume.house
    text
  end

  def monarch_link(monarch)
    link_content = Monarch.monarch_name(monarch)
    return link_content unless Monarch.volumes_by_monarch[monarch]
    link_to link_content, monarch_index_url(:monarch_name => Monarch.slug(monarch))
  end

  def sitting_column_links sitting
    first = Sitting.column_number(sitting.start_column)
    last = Sitting.column_number(sitting.end_column)
    columns = []

    place_holder_blank = ''
    (first % 10).times { |i| columns << place_holder_blank }
    first.upto(last) do |column|
      the_section = sitting.find_section_by_column(column.to_s)
      columns << column_link(column, the_section, sitting)
    end

    rows = []
    columns.in_groups_of(10) {|g| rows << '<tr><td class="column-number">' + g.join('</td><td class="column-number">') + '</td></tr>' }
    rows.join('')
  end

  def column_link column, section, sitting
    column_string = sitting.class.normalized_column(column.to_s)
    if section
      url = column_url(column, section)
      link_to "#{column_string}", url
    else
      "<div class='missing-column'>#{column_string}</div>"
    end
  end
end
