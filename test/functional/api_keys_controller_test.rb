require "test_helper"

class ApiKeysControllerTest < ActionController::TestCase
  context "when not logged in" do
    context "on GET to index" do
      setup { get :index }

      should redirect_to("the sign in page") { sign_in_path }
    end

    context "on GET to new" do
      setup { get :new }

      should redirect_to("the sign in page") { sign_in_path }
    end

    context "on POST to create" do
      setup { post :create, params: { api_key: { name: "test", add_owner: true } } }

      should redirect_to("the sign in page") { sign_in_path }
    end

    context "on DELETE to destroy" do
      setup { post :create, params: { id: 1 } }

      should redirect_to("the sign in page") { sign_in_path }
    end
  end

  context "when logged in" do
    setup do
      @user = create(:user)
      sign_in_as(@user)
    end

    context "on GET to index" do
      context "no api key exists" do
        setup do
          get :index
        end

        should redirect_to("the new api key page") { new_profile_api_key_path }
      end

      context "api key exists" do
        setup do
          @api_key = create(:api_key, user: @user)
          get :index
        end

        should respond_with :success

        should "render api key of user" do
          assert page.has_content? @api_key.name
        end
      end
    end

    context "on GET to new" do
      setup { get :new }

      should respond_with :success

      should "render api key of user" do
        assert page.has_content? "New API key"
      end
    end

    context "on POST to create" do
      context "with successful save" do
        setup do
          post :create, params: { api_key: { name: "test", add_owner: true } }
          Delayed::Worker.new.work_off
        end

        should redirect_to("the key index page") { profile_api_keys_path }
        should "create new key for user" do
          api_key = @user.api_keys.last

          assert_equal "test", api_key.name
          assert api_key.add_owner?
        end
        should "deliver api key created email" do
          refute ActionMailer::Base.deliveries.empty?
          email = ActionMailer::Base.deliveries.last
          assert_equal [@user.email], email.to
          assert_equal ["no-reply@mailer.rubygems.org"], email.from
          assert_equal "New API key created for rubygems.org", email.subject
        end
      end

      context "with unsuccessful save" do
        setup { post :create, params: { api_key: { add_owner: true } } }

        should "show error to user" do
          assert page.has_content? "Name can't be blank"
        end

        should "not create new key for user" do
          assert @user.reload.api_keys.empty?
        end
      end
    end

    context "on DELETE to destroy" do
      context "user is owner of key" do
        setup { @api_key = create(:api_key, user: @user) }

        context "with successful destroy" do
          setup { delete :destroy, params: { id: @api_key.id } }

          should redirect_to("the index api key page") { profile_api_keys_path }
          should "delete api key of user" do
            assert @user.api_keys.empty?
          end
        end

        context "with unsuccessful destroy" do
          setup do
            ApiKey.any_instance.stubs(:destroy).returns(false)
            delete :destroy, params: { id: @api_key.id }
          end

          should redirect_to("the index api key page") { profile_api_keys_path }
          should "not delete api key of user" do
            refute @user.api_keys.empty?
          end
        end
      end

      context "user is not owner of key" do
        setup do
          @api_key = create(:api_key)
          delete :destroy, params: { id: @api_key.id }
        end

        should respond_with :not_found
        should "not delete the api key" do
          assert ApiKey.find(@api_key.id)
        end
      end
    end
  end
end
