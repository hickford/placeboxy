#!/usr/bin/ruby
environment = ENV['DATABASE_URL'] ? 'production' : 'development'

if environment == 'development'
    require './config/environments/development.rb'
    # require and configure pusher
end

require './pb.rb'

dbconfig = YAML.load(File.read('config/database.yml'))
Pb::Models::Base.establish_connection dbconfig[environment]
Pb.create if Pb.respond_to? :create

run Pb

