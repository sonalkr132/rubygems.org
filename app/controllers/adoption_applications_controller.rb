class AdoptionApplicationsController < ApplicationController
  before_action :redirect_to_root, unless: :signed_in?
  before_action :find_rubygem
  before_action :find_adoption_application, only: :update
  before_action :find_applicant, only: :update

  def create
    @adoption_application = @rubygem.adoption_applications.create(adoption_application_params)

    if @adoption_application
      Mailer.delay.adoption_applicationed(@adoption_application)
      redirect_to rubygem_adoptions_path(@rubygem), flash: { success: t(".success", gem: @rubygem.name) }
    else
      render_bad_request
    end
  end

  def update
    if params_status == "approved" && @rubygem.owned_by?(current_user)
      @rubygem.approve_adoption_application!(@adoption_application, current_user.id)
      Mailer.delay.adoption_application_approved(@rubygem, @applicant)

      redirect_to_adoptions_path
    elsif params_status == "canceled" && current_user.can_cancel?(@adoption_application)
      @adoption_application.canceled!
      Mailer.delay.adoption_application_canceled(@rubygem, @applicant) unless @applicant == current_user

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

  def find_adoption_application
    @adoption_application = AdoptionApplication.find(params[:id])
  end

  def find_applicant
    @applicant = User.find(@adoption_application.user_id)
  end

  def redirect_to_adoptions_path
    message = t(".success", user: @applicant.name, gem: @rubygem.name, status: @adoption_application.status)
    redirect_to rubygem_adoptions_path(@rubygem), flash: { success: message }
  end

  def render_bad_request
    render plain: "Invalid adoption application", status: :bad_request
  end
end
