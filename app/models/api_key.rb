class ApiKey < ApplicationRecord
  belongs_to :user
  validates :user, :name, :hashed_key, :expires_at, presence: true
  before_validation :set_expires_at

  def scope
    Gemcutter::API_SCOPES.map { |s| s.to_s.gsub("_", " ") if self.send(s) }.compact.join(", ")
  end

  private

  def set_expires_at
    self.expires_at = Time.zone.now + 180.days
  end
end
