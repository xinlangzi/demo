class Role < ApplicationRecord

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  has_and_belongs_to_many :users, ->{ order('companies.name ASC') }, join_table: "roles_users"
  has_and_belongs_to_many :rights
  has_and_belongs_to_many :default_rights, class_name: 'Right', join_table: 'default_rights_roles'

  before_update do
    throw :abort unless can_update?
  end
  before_destroy do
    throw :abort unless can_destroy?
  end

  DEFAULT_ROLES = %w[Customer Trucker Dispatcher Bookkeeper].freeze

  def rights_tree
    rights.order('rights.controller, rights.name ASC').group_by(&:controller)
  end

  def can_update?
    errors.add(:base, "Default roles (#{DEFAULT_ROLES.join(',')}) cannot be deleted/updated.") if name_changed? && DEFAULT_ROLES.include?(name_was)
    errors[:base].empty?
  end

  def can_destroy?
    errors.add(:base, "Default roles (#{DEFAULT_ROLES.join(',')}) cannot be deleted/updated.") if default?
    errors[:base].empty?
  end

  def default?
    DEFAULT_ROLES.include?(name)
  end

end
