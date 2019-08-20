require 'digest'
require 'bcrypt'

require_relative '../models.rb'

class User < ActiveRecord::Base
  validates :id, presence: true, uniqueness: true
  validates :password, presence: true

  def self.create(name, new_password)
    user = User.new
    user.id = name
    user.password = encrypt(new_password)
    user.save
    user
  end

  def authenticate(confirmed)
    BCrypt::Password.new(self.password) == confirmed
  end

  private

  def self.encrypt(new_password)
    if new_password.present?
      return BCrypt::Password.create(new_password)
    else
      raise ArgumentError
    end
  end
end
