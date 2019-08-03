class ApiKey < ApplicationRecord
  API_SCOPES = %i[index_rubygems push_rubygem yank_rubygem add_owner remove_owner webhook_actions show_dashboard].freeze

  belongs_to :user
  validates :user, :name, :hashed_key, presence: true
  validate :exclusive_show_dashboard_scope, if: :show_dashboard?

  def scope
    API_SCOPES.map { |scope| scope if send(scope) }.compact
  end

  private

  def exclusive_show_dashboard_scope
    errors.add :show_dashboard, "scope must be enabled exclusively" if non_show_dashboard_enabled?
  end

  def non_show_dashboard_enabled?
    scope.tap { |scope| scope.delete(:show_dashboard) }.any?
  end
end
