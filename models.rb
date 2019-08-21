require 'active_record'

config = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection(config['production'])

require_relative './models/user.rb'
