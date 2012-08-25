require "present_on_date"
require "present_on_date_helper"
require "url_date"

ActiveRecord::Base.send(:include, PresentOnDate)
ActionView::Base.send(:include, PresentOnDateHelper)
ActionView::Base.send(:include, PresentOnDateTimelineHelper)

require 'fileutils'

img = File.join(RAILS_ROOT, 'vendor', 'plugins', 'present_on_date', 'images', 'dot.gif')
to = File.join(RAILS_ROOT, 'public', 'images', 'dot.gif')
FileUtils.copy(img, to)

img = File.join(RAILS_ROOT, 'vendor', 'plugins', 'present_on_date', 'images', 'whitedot.gif')
to = File.join(RAILS_ROOT, 'public', 'images', 'whitedot.gif')
FileUtils.copy(img, to)
