require "test_helper"

class IpSpoofingTest < ActionDispatch::IntegrationTest
  setup do
    get "/", headers: { HTTP_CLIENT_IP: "172.16.72.122", HTTP_X_FORWARDED_FOR: "8.8.8.8, 8.8.8.8" }
  end

  should "respond with success" do
    assert_response :bad_request
  end
end
