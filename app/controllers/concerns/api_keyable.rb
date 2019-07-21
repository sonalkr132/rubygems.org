module ApiKeyable
  extend ActiveSupport::Concern

  private

  def api_key_params
    params.require(:api_key).permit(:name, *Gemcutter::API_SCOPES)
  end

  def hashed_key(key)
    Digest::SHA256.hexdigest(key)
  end

  def rubygems_key
    "rubygems_" + SecureRandom.hex(16)
  end
end
