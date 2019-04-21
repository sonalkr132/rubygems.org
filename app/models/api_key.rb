class ApiKey < ApplicationRecord
  belongs_to :user
  validates :user, :name, :hashed_key, :expires_at, presence: true
  before_validation :set_expires_at

  private

  def set_expires_at
    self.expires_at = Time.zone.now + 180.days
  end
end
