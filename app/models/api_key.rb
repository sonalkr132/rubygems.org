class ApiKey < ApplicationRecord
  belongs_to :user
  validates :user, :name, :hashed_key, presence: true

  def scope
    Gemcutter::API_SCOPES.map { |scope| scope if send(scope) }.compact
  end
end
