require "test_helper"

class Api::V1::RubygemsTest < ActionDispatch::IntegrationTest
  setup do
    @key = "12345"
    create(:api_key, key: @key, index_rubygems: true)
  end

  test "request with array of api keys returns unauthorize" do
    get "/api/v1/gems?api_key=#{@key}", as: :json
    assert_response :success

    get "/api/v1/gems?api_key[]=#{@key}&api_key[]=key1", as: :json
    assert_response :unauthorized
  end
end
