class ApiKeysController < ApplicationController
  before_action :redirect_to_root, unless: :signed_in?
  before_action :find_api_key, only: :destroy

  def index
    @api_keys = current_user.api_keys
    redirect_to new_profile_api_key_path if @api_keys.empty?
  end

  def new
    @api_key = current_user.api_keys.build
  end

  def create
    @key = SecureRandom.hex(16)
    @api_key = current_user.api_keys.build(api_key_params.merge(hashed_key: hashed_key))

    if @api_key.save
      flash[:notice] = t(".save_key", key: @key)
      redirect_to profile_api_keys_path
    else
      flash[:error] = @api_key.errors.full_messages.to_sentence
      render :new
    end
  end

  def destroy
    if @api_key.destroy
      flash[:notice] = t(".success", name: @api_key.name)
    else
      flash[:error] = @api_key.errors.full_messages.to_sentence
    end
    redirect_to profile_api_keys_path
  end

  private

  def api_key_params
    params.require(:api_key).permit(:name, *Gemcutter::API_SCOPES)
  end

  def hashed_key
    Digest::SHA256.hexdigest(@key)
  end

  def find_api_key
    @api_key = current_user.api_keys.find(params.require(:id))
  end
end
