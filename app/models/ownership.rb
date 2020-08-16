class Ownership < ApplicationRecord
  belongs_to :rubygem
  belongs_to :user
  belongs_to :authorizer, class_name: "User", optional: true

  validates :user_id, uniqueness: { scope: :rubygem_id }

  delegate :name, to: :user, prefix: :owner
  delegate :name, to: :authorizer, prefix: true, allow_nil: true

  before_create :generate_confirmation_token

  scope :confirmed, -> { where("confirmed_at IS NOT NULL") }
  scope :unconfirmed, -> { where("confirmed_at IS NULL") }

  def self.by_indexed_gem_name
    select("ownerships.*, rubygems.name")
      .left_joins(rubygem: :versions)
      .where(versions: { indexed: true })
      .distinct
      .order("rubygems.name ASC")
  end

  def self.find_by_owner_handle!(handle)
    joins(:user).find_by(users: { handle: handle }) || joins(:user).find_by!(users: { id: handle })
  end

  def self.create_confirmed(rubygem, user)
    ownership = rubygem.ownerships.create(user: user, authorizer: user)
    ownership.confirm!
  end

  def valid_confirmation_token?
    token_expires_at > Time.zone.now
  end

  def generate_confirmation_token
    self.token = SecureRandom.hex(20).encode("UTF-8")
    self.token_expires_at = Time.zone.now + Gemcutter::OWNERSHIP_TOKEN_EXPIRES_AFTER
  end

  def confirm!
    update(confirmed_at: Time.current, token: nil) if unconfirmed?
  end

  def confirmed?
    confirmed_at.present?
  end

  def unconfirmed?
    !confirmed?
  end

  def confirm_and_notify
    confirm! && notify_owner_added
  end

  def destroy_and_notify(remover)
    return false unless safe_destroy
    OwnersMailer.delay.owner_removed(user_id, remover.id, rubygem_id)
  end

  private

  def safe_destroy
    destroy if unconfirmed? || rubygem.owners.many?
  end

  def notify_owner_added
    rubygem.ownership_notifiable_owners.each do |notified_user|
      OwnersMailer.delay.owner_added(user_id, notified_user.id, authorizer.id, rubygem_id)
    end
  end
end
