# frozen_string_literal: true

class User < ActiveRecord::Base
  has_secure_password

  validates :username, presence: true
  validates :password, presence: true

  has_many :comments

  before_create do |u|
    u.id = SecureRandom.uuid
  end
end
