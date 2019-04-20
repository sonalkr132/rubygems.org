class ApiKeysController < ApplicationController
  before_action :redirect_to_root, unless: :signed_in?

  def index
    @api_keys = current_user.api_keys
    redirect_to new_profile_api_key_path if @api_keys.empty?
  end

  def new
    @api_key  = current_user.api_keys.build
  end

  def create
    @key = SecureRandom.hex(16)
    @api_key = current_user.api_keys.build(api_key_params)

    if @api_key.save
      flash[:notice] = "Please save this api key some place safe: #{@key}.\
        We won't be able to show this to you again."
      redirect_to profile_api_keys_path
    else
      flash[:error] = @api_key.errors.full_messages.to_sentence
      render :new
    end
  end

  def destroy
    @api_key = ApiKey.find(id_params)

    if @api_key.destroy
      flash[:notice] = "Successfully deleted API key"
    else
      flash[:error] = @api_key.errors.full_messages.to_sentence
    end
    redirect_to profile_api_keys_path
  end

  private

  def api_key_params
    params.require(:api_key).permit(:name, *Gemcutter::API_SCOPES).merge(hashed_key: Digest::SHA256.hexdigest(@key))
  end

  def id_params
    params.require("id")
  end
end
