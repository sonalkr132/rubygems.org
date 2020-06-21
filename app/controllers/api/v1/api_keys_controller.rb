class Api::V1::ApiKeysController < Api::BaseController
  def show
    authenticate_or_request_with_http_basic do |username, password|
      user = User.authenticate(username, password)
      otp = request.headers["HTTP_OTP"]
      if user&.mfa_api_authorized?(otp)
        respond_to do |format|
          format.any(:all) { render plain: user.api_key }
          format.json { render json: { rubygems_api_key: user.api_key } }
          format.yaml { render plain: { rubygems_api_key: user.api_key }.to_yaml }
        end
      elsif user&.mfa_enabled?
        prompt_text = otp.present? ? t(:otp_incorrect) : t(:otp_missing)
        render plain: prompt_text, status: :unauthorized
      else
        false
      end
    end
  end
end
