namespace :cron do 

  task :expire_frontpage_cache => :environment do
     ActionController::Base::expire_page('/')
     DEFAULT_FEEDS.each do |years|
       ActionController::Base::expire_page("/years-ago/#{years}.xml")
    end
  end

end
