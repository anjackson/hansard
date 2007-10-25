require 'mongrel_cluster/recipes'
require 'parl_recipes'

set :application, "hansard"
set :repository,  "http://proto.parliament.uk/svn/hansard/trunk"
set :apache_conf_dir, "/usr/local/apache/conf"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

role :app, "10.100.10.16"
role :web, "10.100.10.16"
role :db,  "10.100.10.16", :primary => true

set :user, "cap"               # defaults to the currently logged in user
set :use_sudo, false

ssh_options[:paranoid] = false 

namespace :deploy do 
  desc "Softlink the 'hansard_data/data' directory to 'data' and 'hansard_data/xml' to 'xml'"
  task :create_data_softlinks, :roles => ["app"] do   
    invoke_command "ln -s /u/apps/hansard_data/data /u/apps/#{application}/current/data", :via => "sudo"
    invoke_command "rm -rf /u/apps/#{application}/current/xml", :via => "sudo" 
    invoke_command "ln -s /u/apps/hansard_data/xml /u/apps/#{application}/current/xml", :via => "sudo"
  end

  desc "Softlink the 'vendor/plugins/acts_as_solr/solr/solr/data' directory to 'shared/system/solr_data'"
  task :create_solr_softlink, :roles => ["app"] do
    invoke_command "rm -rf /u/apps/#{application}/current/vendor/plugins/acts_as_solr/solr/solr/data", :via => "sudo" 
    invoke_command "ln -s /u/apps/#{application}/shared/solr_data /u/apps/#{application}/current/vendor/plugins/acts_as_solr/solr/solr/data", :via => "sudo"
    invoke_command "rm -rf /u/apps/#{application}/current/vendor/plugins/acts_as_solr/solr/tmp", :via => "sudo" 
    invoke_command "ln -s /u/apps/#{application}/shared/solr_tmp /u/apps/#{application}/current/vendor/plugins/acts_as_solr/solr/tmp", :via => "sudo"  
  end
  
end

after "deploy:document", "deploy:create_data_softlinks", "deploy:create_solr_softlink"
