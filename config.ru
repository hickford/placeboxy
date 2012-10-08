#!/usr/bin/ruby
require 'erb'
require 'yaml'
$stdout.sync = true

environment = ENV['RACK_ENV'] || 'development'
dbconfig = YAML.load(ERB.new(File.read('config/database.yml')).result)

require './pb.rb'
# create db folder here?
# set SESSION_SECRET environment variable?
Pb::Models::Base.establish_connection dbconfig[environment]
Pb.create if Pb.respond_to? :create
run Pb
