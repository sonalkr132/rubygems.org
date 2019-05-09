require "test_helper"

class ApiKeyTest < ActiveSupport::TestCase
  should belong_to :user
  should validate_presence_of(:name)
  should validate_presence_of(:user)
  should validate_presence_of(:hashed_key)

  should "be valid with factory" do
    assert build(:api_key).valid?
  end

  should "set expiries_at time" do
    assert create(:api_key).expires_at > Time.zone.now
  end
end
