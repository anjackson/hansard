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
  desc "Softlink the 'hansard_data/data' directory to 'data'"
  task :create_data_softlink, :roles => ["app"] do   
    invoke_command "ln -s /u/apps/hansard_data/data /u/apps/#{application}/current/data", :via => "sudo"
  end
end

after "deploy:document", "deploy:create_data_softlink"
