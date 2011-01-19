#!/usr/bin/ruby
environment = ENV['DATABASE_URL'] ? 'production' : 'development'

require './pb.rb'

dbconfig = YAML.load(File.read('config/database.yml'))
Pb::Models::Base.establish_connection dbconfig[environment]
Pb.create if Pb.respond_to? :create

run Pb

