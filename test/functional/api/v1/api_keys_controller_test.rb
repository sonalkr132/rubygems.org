require "test_helper"

class Api::V1::ApiKeysControllerTest < ActionController::TestCase
  should "route new paths to new controller" do
    route = { controller: "api/v1/api_keys", action: "show" }
    assert_recognizes(route, "/api/v1/api_key")
  end

  context "on GET to show with no credentials" do
    setup do
      get :show
    end
    should "deny access" do
      assert_response 401
      assert_match "HTTP Basic: Access denied.", @response.body
    end
  end

  def authorize_with(str)
    @request.env["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64(str)
  end

  context "on GET to show with bad credentials" do
    setup do
      @user = create(:user)
      authorize_with("bad:creds")
      get :show
    end
    should "deny access" do
      assert_response 401
      assert_match "HTTP Basic: Access denied.", @response.body
    end
  end

  context "when user has enabled MFA for API" do
    setup do
      @user = create(:user)
      @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
      authorize_with("#{@user.email}:#{@user.password}")
    end

    context "on GET to show without OTP" do
      setup do
        get :show
      end

      should "deny access" do
        assert_response 401
        assert_match I18n.t("otp_missing"), @response.body
      end
    end

    context "on GET to show with incorrect OTP" do
      setup do
        @request.env["HTTP_OTP"] = "11111"
        get :show
      end

      should "deny access" do
        assert_response 401
        assert_match I18n.t("otp_incorrect"), @response.body
      end
    end

    context "on GET to show with correct OTP" do
      setup do
        @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.mfa_seed).now
        get :show
      end

      should respond_with :success
      should "return API key" do
        assert_equal @user.api_key, @response.body
      end
      should "not sign in user" do
        refute @controller.request.env[:clearance].signed_in?
      end
    end

    context "on POST to create without OTP" do
      setup do
        post :create
      end

      should "deny access" do
        assert_response 401
        assert_match I18n.t("otp_missing"), @response.body
      end
    end

    context "on POST to create with incorrect OTP" do
      setup do
        @request.env["HTTP_OTP"] = "11111"
        post :create
      end

      should "deny access" do
        assert_response 401
        assert_match I18n.t("otp_incorrect"), @response.body
      end
    end

    context "on POST to create with correct OTP" do
      setup do
        @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.mfa_seed).now
        post :create, params: { name: "test", index_rubygems: "true" }
      end

      should respond_with :success
      should "return API key" do
        hashed_key = @user.api_keys.first.hashed_key
        assert_equal hashed_key, Digest::SHA256.hexdigest(@response.body)
      end
    end
  end

  # this endpoint is used by rubygems
  context "on GET to show with TEXT and with confirmed user" do
    setup do
      @user = create(:user)
      authorize_with("#{@user.email}:#{@user.password}")
      get :show, format: "text"
    end
    should respond_with :success
    should "return API key" do
      assert_equal @user.api_key, @response.body
    end
    should "not sign in user" do
      refute @controller.request.env[:clearance].signed_in?
    end
  end

  def self.should_respond_to(format, to_meth = :to_s)
    context "with #{format.to_s.upcase} and with confirmed user" do
      setup do
        @user = create(:user)
        authorize_with("#{@user.email}:#{@user.password}")
        get :show, format: format
      end
      should respond_with :success
      should "return API key" do
        response = yield(@response.body)
        assert_not_nil response
        assert_kind_of Hash, response
        assert_equal @user.api_key, response["rubygems_api_key".send(to_meth)]
      end
    end
  end

  context "on GET to show" do
    should_respond_to(:json) do |body|
      JSON.load body
    end

    should_respond_to(:yaml, :to_sym) do |body|
      YAML.safe_load(body, [Symbol])
    end
  end

  context "on POST to create with bad credentials" do
    setup do
      authorize_with("bad:creds")
      post :create
    end
    should "deny access" do
      assert_response 401
      assert_match "HTTP Basic: Access denied.", @response.body
    end
  end

  context "on POST to create with correct credentials" do
    setup do
      @user = create(:user)
      authorize_with("#{@user.email}:#{@user.password}")
      post :create, params: { name: "test", index_rubygems: "true" }, format: "text"
      Delayed::Worker.new.work_off
    end
    should respond_with :success
    should "return API key" do
      hashed_key = @user.api_keys.first.hashed_key
      assert_equal hashed_key, Digest::SHA256.hexdigest(@response.body)
    end
    should "deliver api key created email" do
      refute ActionMailer::Base.deliveries.empty?
      email = ActionMailer::Base.deliveries.last
      assert_equal [@user.email], email.to
      assert_equal ["no-reply@mailer.rubygems.org"], email.from
      assert_equal "New API key created for rubygems.org", email.subject
    end
  end
end
