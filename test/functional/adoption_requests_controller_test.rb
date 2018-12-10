require 'test_helper'

class AdoptionApplicationsControllerTest < ActionController::TestCase
  context "when logged in" do
    setup do
      @user = create(:user, handle: "johndoe")
      @rubygem = create(:rubygem)
      sign_in_as(@user)
    end

    context "on POST to create" do
      setup do
        post :create, params: { rubygem_id: @rubygem.name, adoption_application: { note: "example note" } }
      end

      should redirect_to("rubygems adoptions index") { rubygem_adoptions_path(@rubygem) }
      should "set flash success" do
        assert_equal "adoption application sent to owner(s) of #{@rubygem.name}", flash[:success]
      end
      should "set opened adoption_application status" do
        assert_equal "opened", @user.adoption_applications.find_by(rubygem_id: @rubygem.id).status
      end
    end

    context "on PUT to update" do
      context "with status approved" do
        context "when user is owner of gem" do
          setup do
            @adoption_application = create(:adoption_application, rubygem: @rubygem)
            @rubygem.ownerships.create(user: @user)
            put :update, params: { rubygem_id: @rubygem.name, id: @adoption_application.id, adoption_application: { status: "approved" } }
          end

          should redirect_to("rubygems adoptions index") { rubygem_adoptions_path(@rubygem) }
          should "set flash success" do
            assert_equal "#{@adoption_application.user.name}'s adoption application for #{@rubygem.name} has been approved", flash[:success]
          end
          should "set approved adoption application status" do
            @adoption_application.reload
            assert_equal "approved", @adoption_application.status
          end
          should "add user as owner" do
            assert @rubygem.owned_by?(@adoption_application.user)
          end
        end

        context "when user is not owner of gem" do
          setup do
            @adoption_application = create(:adoption_application, rubygem: @rubygem)
            put :update, params: { rubygem_id: @rubygem.name, id: @adoption_application.id, adoption_application: { status: "approved" } }
          end

          should respond_with :bad_request
          should "not set approved adoption application status" do
            @adoption_application.reload
            assert_not_equal "approved", @adoption_application.status
          end
        end
      end

      context "with status canceled" do
        context "when user created adoption application" do
          setup do
            @adoption_application = create(:adoption_application, user: @user)
            put :update, params: { rubygem_id: @rubygem.name, id: @adoption_application.id, adoption_application: { status: "canceled" } }
          end

          should redirect_to("rubygems adoptions index") { rubygem_adoptions_path(@rubygem) }
          should "set flash success" do
            assert_equal "#{@user.name}'s adoption application for #{@rubygem.name} has been canceled", flash[:success]
          end
          should "set canceled adoption_application status" do
            @adoption_application.reload
            assert_equal "canceled", @adoption_application.status
          end
        end

        context "when user is owner of gem" do
          setup do
            @adoption_application = create(:adoption_application, rubygem: @rubygem)
            @rubygem.ownerships.create(user: @user)
            put :update, params: { rubygem_id: @rubygem.name, id: @adoption_application.id, adoption_application: { status: "canceled" } }
          end

          should redirect_to("rubygems adoptions index") { rubygem_adoptions_path(@rubygem) }
          should "set flash success" do
            assert_equal "#{@adoption_application.user.name}'s adoption application for #{@rubygem.name} has been canceled", flash[:success]
          end
          should "set canceled adoption application status" do
            @adoption_application.reload
            assert_equal "canceled", @adoption_application.status
          end
        end

        context "when user is neither owner nor adoption application requester" do
          setup do
            @adoption_application = create(:adoption_application, rubygem: @rubygem)
            put :update, params: { rubygem_id: @rubygem.name, id: @adoption_application.id, adoption_application: { status: "canceled" } }
          end

          should respond_with :bad_request
          should "not set canceled adoption application status" do
            @adoption_application.reload
            assert_not_equal "canceled", @adoption_application.status
          end
        end
      end
    end
  end

  context "when not logged in" do
    setup do
      @rubygem = create(:rubygem)
    end

    context "on POST to create" do
      setup do
        post :create, params: { rubygem_id: @rubygem.name, adoption_application: { note: "example note" } }
      end

      should redirect_to("home") { root_path }
      should "not create adoption application" do
        assert_empty @rubygem.adoption_applications
      end
    end

    context "on PUT to update" do
      setup do
        @adoption_application = create(:adoption_application, rubygem: @rubygem)
        put :update, params: { rubygem_id: @rubygem.name, id: @adoption_application.id, adoption_application: { status: "approved" } }
      end

      should redirect_to("home") { root_path }
      should "not approve adoption application" do
        assert_equal "opened", @adoption_application.status
      end
    end
  end
end
