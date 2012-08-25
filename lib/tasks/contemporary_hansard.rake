require File.dirname(__FILE__) + '/../hansard/hansard_transformer'

namespace :hansard do

  task :transform => :environment do
    path = '/Users/x/apps/uk/contemporary_hansard/Mekon/XML'
    source = "#{path}/new.xml"
    result = "#{path}/transformed.xml"
    transformer = Hansard::Transformer.new(source, result)
    transformer.transform
  end

end
