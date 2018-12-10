require 'test_helper'

class AdoptionApplicationTest < ActiveSupport::TestCase
  subject { create(:adoption_application) }

  should belong_to :user
  should belong_to :rubygem
  should validate_presence_of(:rubygem)
  should validate_presence_of(:user)

  context "validation" do
    should "not allow unspecified status" do
      assert_raises(ArgumentError) { build(:adoption_application, status: "unknown") }

      adoption_application = build(:adoption_application, status: "opened")
      assert adoption_application.valid?
      assert_nil adoption_application.errors[:handle].first
    end
  end
end
