require "test_helper"

class Api::V1::RubygemsTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    Rack::Attack.cache.store.clear
  end

  def keys(level, remote_ip)

  end

  test "request with array of api keys returns unauthorize" do
    get "/api/v1/gems?api_key=#{@user.api_key}", as: :json
    assert_response :success

    get "/api/v1/gems?api_key[]=#{@user.api_key}&api_key[]=key1", as: :json
    assert_response :unauthorized
  end

  test "request has remote addr present" do
    puts Rails.cache.instance_variable_get("@data").keys.inspect
    ip_address = "1.2.3.4"

    period            = Rack::Attack::PUSH_LIMIT_PERIOD
    time_counter      = (Time.now.to_i / period).to_i
    # counter may have incremented by 1 since the key was set, best to reset prev counter as well.
    # pre time counter/window key is applicable for +1 second after the counter has changed
    # see: https://github.com/kickstarter/rack-attack/pull/85
    prev_time_counter = time_counter - 1
    prefix            = Rack::Attack.cache.prefix

    key = "#{prefix}:#{time_counter}:api/push/ip:#{ip_address}"
    puts "#{key} - #{Rack::Attack.cache.count(key, period).inspect}"
    RackAttackReset.expects(:gem_push_backoff).with(ip_address).once

    post "/api/v1/gems",
          params: gem_file("test-1.0.0.gem").read,
          headers: { REMOTE_ADDR: ip_address, HTTP_AUTHORIZATION: @user.api_key, CONTENT_TYPE: "application/octet-stream" }

    puts @response.headers
    puts "#{key} - #{Rack::Attack.cache.count(key, period).inspect}"
    assert_response :success
  end

  test "request has remote addr absent" do
    RackAttackReset.expects(:gem_push_backoff).never

    post "/api/v1/gems",
          params: gem_file("test-1.0.0.gem").read,
          headers: { REMOTE_ADDR: "", HTTP_AUTHORIZATION: @user.api_key, CONTENT_TYPE: "application/octet-stream" }

    assert_response :success
  end
end
