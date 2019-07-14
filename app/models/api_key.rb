class ApiKey < ApplicationRecord
  belongs_to :user
  validates :user, :name, :hashed_key, presence: true
end
