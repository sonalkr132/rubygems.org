class AdoptionApplicationsController < ApplicationController
  before_action :redirect_to_root, unless: :signed_in?
  before_action :find_rubygem
  before_action :find_adoption_application_and_applicant, only: :update

  def create
    adoption_application = @rubygem.adoption_applications.build(adoption_application_params)

    if adoption_application.save
      Mailer.delay.adoption_application_applied(adoption_application)
      redirect_to rubygem_adoptions_path(@rubygem), flash: { success: t(".success", gem: @rubygem.name) }
    else
      redirect_to rubygem_adoptions_path(@rubygem), flash: { error: adoption_application.errors.full_messages.to_sentence }
    end
  end

  def update
    if params_status == "approved" && @rubygem.owned_by?(current_user)
      @rubygem.approve_adoption_application!(@adoption_application, current_user.id)
      Mailer.delay.adoption_application_approved(@rubygem, @applicant)

      redirect_to_adoptions_path
    elsif params_status == "closed" && current_user.can_close?(@adoption_application)
      @adoption_application.closed!
      Mailer.delay.adoption_application_closed(@rubygem, @applicant) unless @applicant == current_user

      redirect_to_adoptions_path
    else
      render_bad_request
    end
  end

  private

  def adoption_application_params
    params.require(:adoption_application).permit(:note).merge(user_id: current_user.id, status: :opened)
  end

  def params_status
    params[:adoption_application][:status]
  end

  def find_adoption_application_and_applicant
    @adoption_application = AdoptionApplication.find(params[:id])
    @applicant = @adoption_application.user
  end

  def redirect_to_adoptions_path
    message = t(".success", user: @applicant.name, gem: @rubygem.name, status: @adoption_application.status)
    redirect_to rubygem_adoptions_path(@rubygem), flash: { success: message }
  end
end
