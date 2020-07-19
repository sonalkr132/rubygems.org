module ApiKeyable
  extend ActiveSupport::Concern

  private

  def hashed_key(key)
    Digest::SHA256.hexdigest(key)
  end

  def generate_unique_rubygems_key
    loop do
      key = generate_rubygems_key
      return key if ApiKey.where(hashed_key: hashed_key(key)).empty?
    end
  end

  def generate_rubygems_key
    "rubygems_" + SecureRandom.hex(24)
  end
end
