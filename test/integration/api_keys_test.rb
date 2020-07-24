require "test_helper"

class ApiKeysTest < SystemTest
  setup do
    @user = create(:user)

    visit sign_in_path
    fill_in "Email or Username", with: @user.email
    fill_in "Password", with: @user.password
    click_button "Sign in"
  end

  test "creating new api key" do
    visit profile_api_keys_path

    fill_in "api_key[name]", with: "test"
    check "api_key[index_rubygems]"
    click_button "Create"

    assert page.has_content? "Please save the key in a secret management system"
  end

  test "deleting api key" do
    create(:api_key, user: @user)

    visit profile_api_keys_path
    click_link "Delete"

    assert page.has_content? "New API key"
  end

  test "deleting all api key" do
    create(:api_key, user: @user)

    visit profile_api_keys_path
    click_link "Delete all"

    assert page.has_content? "New API key"
  end
end
