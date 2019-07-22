require "test_helper"

class ApiKeyTest < ActiveSupport::TestCase
  should belong_to :user
  should validate_presence_of(:name)
  should validate_presence_of(:user)
  should validate_presence_of(:hashed_key)

  should "be valid with factory" do
    assert build(:api_key).valid?
  end

  context "#scope" do
    setup do
      @api_key = create(:api_key, index_rubygems: true, push_rubygem: true)
    end

    should "something" do
      assert_equal %i[index_rubygems push_rubygem], @api_key.scope
    end
  end
end
