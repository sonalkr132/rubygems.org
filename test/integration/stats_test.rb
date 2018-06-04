require 'test_helper'

class StatsTest < SystemTest
  test "page params is not integer" do
    path_with_xss = '/stats?page="3\""'
    visit URI.encode(path_with_xss)
    assert page.has_content? "Stats"
  end
end
