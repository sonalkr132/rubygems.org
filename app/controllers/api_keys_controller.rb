class ApiKeysController < ApplicationController
  include ApiKeyable
  before_action :redirect_to_signin, unless: :signed_in?

  def index
    @api_keys = current_user.api_keys
    redirect_to new_profile_api_key_path if @api_keys.empty?
  end

  def new
    @api_key = current_user.api_keys.build
  end

  def create
    key = generate_unique_rubygems_key
    @api_key = current_user.api_keys.build(api_key_params.merge(hashed_key: hashed_key(key)))

    if @api_key.save
      Mailer.delay.api_key_created(@api_key.id)

      flash[:notice] = t(".save_key", key: key)
      redirect_to profile_api_keys_path
    else
      flash[:error] = @api_key.errors.full_messages.to_sentence
      render :new
    end
  end

  def destroy
    api_key = current_user.api_keys.find(params.require(:id))

    if api_key.destroy
      flash[:notice] = t(".success", name: api_key.name)
    else
      flash[:error] = api_key.errors.full_messages.to_sentence
    end
    redirect_to profile_api_keys_path
  end
end
