require "test_helper"

class OwnersControllerTest < ActionController::TestCase
  include ActionMailer::TestHelper

  context "When logged in" do
    setup do
      user = create(:user)
      @rubygem = create(:rubygem)
      create(:ownership, user: user, rubygem: @rubygem)
      sign_in_as(user)
    end

    context "on GET to index" do
      context "when user owns the gem" do
        setup do
          get :index, params: { rubygem_id: @rubygem.name }
        end

        should respond_with :success
        should "render all gem owners in owners table" do
          @rubygem.ownerships.each do |o|
            assert page.has_content?(o.owner_name)
          end
        end
      end

      context "when user does not own the gem" do
        setup do
          @other_user = create(:user)
          sign_in_as(@other_user)
          get :index, params: { rubygem_id: @rubygem.name }
        end

        should redirect_to("the sign in page") { sign_in_path }
      end
    end

    context "on POST to create ownership" do
      context "with correct params" do
        setup do
          @new_owner = create(:user)
          post :create, params: { handle: @new_owner.display_id, rubygem_id: @rubygem.name }
        end

        should redirect_to("ownerships index") { rubygem_owners_path(@rubygem) }
        should "add unconfirmed ownership record" do
          assert @rubygem.owners_including_unconfirmed.include?(@new_owner)
          assert_nil @rubygem.ownerships_including_unconfirmed.find_by(user: @new_owner).confirmed_at
        end
        should "set success notice flash" do
          expected_notice = "Owner added successfully. A confirmation mail has been sent to #{@new_owner.handle}'s email"
          assert_equal expected_notice, flash[:notice]
        end
        should "send confirmation email" do
          ActionMailer::Base.deliveries.clear
          Delayed::Worker.new.work_off
          assert_emails 1
          assert_equal "Please confirm the ownership of #{@rubygem.name} gem on RubyGems.org", last_email.subject
          assert_equal [@new_owner.email], last_email.to
        end
      end

      context "with incorrect params" do
        context "user doesn't exist" do
          setup do
            post :create, params: { handle: "no_user", rubygem_id: @rubygem.name }
          end

          should "show error message" do
            expected_alert = "User must exist"
            assert_equal expected_alert, flash[:alert]
          end

          should "not send confirmation email" do
            ActionMailer::Base.deliveries.clear
            Delayed::Worker.new.work_off
            assert_emails 0
          end
        end

        context "ownership exists" do
          setup do
            @new_owner = create(:user)
            create(:ownership, rubygem: @rubygem, user: @new_owner)
            post :create, params: { handle: @new_owner.handle, rubygem_id: @rubygem.name }
          end

          should "show error message" do
            expected_alert = "User has already been taken"
            assert_equal expected_alert, flash[:alert]
          end
        end
      end
    end

    context "on DELETE to owners" do
      context "gem has more than one owners" do
        setup do
          @second_user = create(:user)
          @ownership = create(:ownership, rubygem: @rubygem, user: @second_user)
          delete :destroy, params: { rubygem_id: @rubygem.name, handle: @second_user.display_id }
        end
        should redirect_to("ownership index") { rubygem_owners_path(@rubygem) }
        should "remove the ownership record" do
          refute @rubygem.owners_including_unconfirmed.include?(@second_user)
        end
        should "send email notifications about owner removal" do
          ActionMailer::Base.deliveries.clear
          Delayed::Worker.new.work_off

          assert_emails 1
          assert_contains last_email.subject, "You were removed as an owner to #{@rubygem.name} gem"
          assert_equal [@second_user.email], last_email.to
        end
      end

      context "gem has only one owner" do
        setup do
          @last_ownership = @rubygem.ownerships.last
          delete :destroy, params: { rubygem_id: @rubygem.name, handle: @last_ownership.user.display_id }
        end
        should redirect_to("ownership index") { rubygem_owners_path(@rubygem) }
        should "not remove the ownership record" do
          assert @rubygem.owners_including_unconfirmed.include?(@last_ownership.user)
        end
        should "should flash error" do
          assert_equal "Owner cannot be removed!", flash[:alert]
        end
        should "not send email notifications about owner removal" do
          ActionMailer::Base.deliveries.clear
          Delayed::Worker.new.work_off
          assert_emails 0
        end
      end
    end

    context "on GET to resend confirmation" do
      setup do
        @new_owner = create(:user)
        @ownership = create(:ownership, :unconfirmed, rubygem: @rubygem, user: @new_owner)
        sign_in_as(@new_owner)
      end
      context "with correct params" do
        setup do
          get :resend_confirmation, params: { rubygem_id: @rubygem.name, handle: @new_owner.display_id }
        end

        should redirect_to("rubygem show") { rubygem_path(@rubygem) }
        should "set success notice flash" do
          success_flash = "A confirmation mail has been re-sent to #{@new_owner.handle}'s email"
          assert_equal success_flash, flash[:notice]
        end
        should "resend confirmation email" do
          ActionMailer::Base.deliveries.clear
          Delayed::Worker.new.work_off
          assert_emails 1
          assert_equal "Please confirm the ownership of #{@rubygem.name} gem on RubyGems.org", last_email.subject
          assert_equal [@new_owner.email], last_email.to
        end
      end

      context "with incorrect params" do
        context "gem not found" do
          setup do
            get :resend_confirmation, params: { rubygem_id: "no_gem", handle: @new_owner.display_id }
          end

          should "show 404 error page" do
            assert_response :not_found
          end

          should "not resend confirmation email" do
            ActionMailer::Base.deliveries.clear
            Delayed::Worker.new.work_off
            assert_emails 0
          end
        end

        context "with incorrect handle" do
          setup do
            get :resend_confirmation, params: { rubygem_id: @rubygem.name, handle: "no_handle" }
          end

          should "resend to signed in user irrespective of handle" do
            assert_redirected_to @rubygem
            success_flash = "A confirmation mail has been re-sent to #{@new_owner.handle}'s email"
            assert_equal success_flash, flash[:notice]
          end

          should "resend confirmation email to signed in" do
            ActionMailer::Base.deliveries.clear
            Delayed::Worker.new.work_off
            assert_emails 1
            assert_equal "Please confirm the ownership of #{@rubygem.name} gem on RubyGems.org", last_email.subject
            assert_equal [@new_owner.email], last_email.to
          end
        end

        context "save failed" do
          setup do
            Ownership.any_instance.stubs(:save).returns(false)
            get :resend_confirmation, params: { rubygem_id: @rubygem.name, handle: @new_owner.display_id }
          end

          should "show alert" do
            assert_redirected_to @rubygem
            success_flash = "Something went wrong. Please try again."
            assert_equal success_flash, flash[:alert]
          end

          should "not resend confirmation email" do
            ActionMailer::Base.deliveries.clear
            Delayed::Worker.new.work_off
            assert_emails 0
          end
        end
      end
    end
  end

  context "When user not logged in" do
    setup do
      @user = create(:user)
      @rubygem = create(:rubygem)
    end

    context "on GET to confirm" do
      setup do
        create(:ownership, rubygem: @rubygem)
        @ownership = create(:ownership, :unconfirmed, user: @user, rubygem: @rubygem)
      end

      context "when token has not expired" do
        setup do
          get :confirm, params: { rubygem_id: @rubygem.name, token: @ownership.token }
          @ownership.reload
        end

        should "confirm ownership" do
          assert @ownership.confirmed?
          assert redirect_to("rubygem show") { rubygem_path(@rubygem) }
          assert_equal flash[:notice], "You are added as an owner to #{@rubygem.name} gem!"
        end

        should "not sign in the user" do
          refute @controller.request.env[:clearance].signed_in?
        end

        should "send email notifications about new owner" do
          ActionMailer::Base.deliveries.clear
          Delayed::Worker.new.work_off

          owner_added_email_subjects = ActionMailer::Base.deliveries.map(&:subject)
          assert_contains owner_added_email_subjects, "You were added as an owner to #{@rubygem.name} gem"
          assert_contains owner_added_email_subjects, "User #{@user.handle} was added as an owner to #{@rubygem.name} gem"

          owner_added_email_to = ActionMailer::Base.deliveries.map(&:to).flatten
          assert_same_elements @rubygem.owners.map(&:email), owner_added_email_to
        end
      end

      context "when token has expired" do
        setup do
          travel_to Time.current + 3.days
          get :confirm, params: { rubygem_id: @rubygem.name, token: @ownership.token }
        end

        should "warn about invalid token" do
          assert respond_with :success
          assert_equal flash[:alert], "The confirmation token has expired. Please try resending the token"
          assert @ownership.unconfirmed?
        end

        should "not send email notification about owner added" do
          ActionMailer::Base.deliveries.clear
          Delayed::Worker.new.work_off
          assert_emails 0
        end
      end
    end

    context "on GET to index" do
      setup do
        get :index, params: { rubygem_id: @rubygem.name }
      end

      should "redirect to sign in path" do
        assert redirect_to("sign in") { sign_in_path }
      end
    end

    context "on POST to add owners" do
      setup do
        new_owner = create(:user)
        post :create, params: { handle: new_owner.display_id, rubygem_id: @rubygem.name }
      end

      should "redirect to sign in path" do
        assert redirect_to("sign in") { sign_in_path }
      end
    end

    context "on DELETE to remove owner" do
      setup do
        create(:ownership, rubygem: @rubygem, user: @user)
        delete :destroy, params: { rubygem_id: @rubygem.name, handle: @user.display_id }
      end

      should "redirect to sign in path" do
        assert redirect_to("sign in") { sign_in_path }
      end
    end
  end
end
