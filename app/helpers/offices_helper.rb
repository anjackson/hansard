module OfficesHelper
  
  def activate_links text
    text.gsub(/((http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?)/, '<a href=\'\1\'>\1</a>')
  end
    
  def merge_office_info(id, count)
    "#{Office.find(id).name} #{pluralize(count, "occurrence")}"
  end 
end
