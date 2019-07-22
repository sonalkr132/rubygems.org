class Api::V1::ApiKeysController < Api::BaseController
  include ApiKeyable

  def show
    authenticate_or_request_with_http_basic do |username, password|
      user = User.authenticate(username, password)
      check_mfa(user) { respond_with user.api_key }
    end
  end

  def create
    authenticate_or_request_with_http_basic do |username, password|
      user = User.authenticate(username, password)

      check_mfa(user) do
        key = rubygems_key
        api_key = user.api_keys.build(api_key_params.merge(hashed_key: hashed_key(key)))

        if api_key.save
          Mailer.delay.api_key_created(api_key.id)
          respond_with key
        else
          respond_with api_key.errors.full_messages.to_sentence
        end
      end
    end
  end

  private

  def check_mfa(user)
    if user&.mfa_api_authorized?(otp)
      yield
    elsif user&.mfa_enabled?
      prompt_text = otp.present? ? t(:otp_incorrect) : t(:otp_missing)
      render plain: prompt_text, status: :unauthorized
    else
      false
    end
  end

  def respond_with(msg)
    respond_to do |format|
      format.any(:all) { render plain: msg }
      format.json { render json: { rubygems_api_key: msg } }
      format.yaml { render plain: { rubygems_api_key: msg }.to_yaml }
    end
  end

  def otp
    request.headers["HTTP_OTP"]
  end
end
