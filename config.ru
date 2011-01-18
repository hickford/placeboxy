#!/usr/bin/ruby
environment = ENV['DATABASE_URL'] ? 'production' : 'development'

if environment == 'development'
    # require './config/environments/development.rb'
    # require and configure pusher
end

require './pb.rb'

dbconfig = YAML.load(File.read('config/database.yml'))
Pb::Models::Base.establish_connection dbconfig[environment]
Pb.create if Pb.respond_to? :create

puts "loading boggle server.."
require 'boggle_server'
BoggleServer::server_assure
puts "boggle server loaded? %s" % BoggleServer::server_running?

run Pb

