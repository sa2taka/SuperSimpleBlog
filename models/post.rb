require_relative '../models.rb'

class Post < ActiveRecord::Base
  belongs_to :user
end
