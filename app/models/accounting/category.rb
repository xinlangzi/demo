#encoding: utf-8
class Accounting::Category < ApplicationRecord
  self.table_name = "accounting_categories"

  COST = "cost"
  REVENUE = "revenue"
  LABEL = " — "

  has_ancestry

  validates :name, :feature, presence: true
  validates :name, uniqueness: {scope: [:feature], case_sensitive: false}

  belongs_to :accounting_group, class_name: 'Accounting::Group', foreign_key: :accounting_group_id
  has_many :line_items, class_name: 'Accounting::LineItem'
  has_many :container_charges, as: :chargable
  has_many :credits, as: :catalogable

  enum feature: { cost: 0, revenue: 1 }

  scope :for_user, ->(user){
    case user.class.to_s
    when 'SuperAdmin'
      all
    when 'Admin'
      if user.has_role?(:accounting)
        all
      else
        where("IFNULL(acct_only, false) = ?", false)
      end
    else raise "Authentication / Access error for #{user.class}"
    end
  }

  scope :toppest, ->(type){
    where(ancestry: nil).
    where(feature: Accounting::Category.features[type.to_sym]) 
}
  scope :undeleted, ->{ where("deleted_at is NULL") }
  scope :for_container, ->{ where(for_container: true) }

  default_scope { order('accounting_categories.name ASC') }

  def self.roots(ids)
    ids.collect{|id| find(id).root}.uniq
  end

  def filter_children(ids)
    all = ids.collect{|id| self.class.find(id).me_with_ancestors_ids}.flatten
    self.children.select{|child| all.include?(child.id) }
  end

  def total_with_descendant(amount_by_category)
    ids = (descendant_ids << id)&(amount_by_category.keys)
    ids.collect{|id| amount_by_category[id]}.sum
  end

  def me_with_ancestors_ids
    ancestor_ids << self.id
  end

  def me_with_ancestors
    ancestors.to_a << self
  end

  def self.parent_options(user, type, current=nil, include_deleted=true)
    array = []
    categories = if current
      for_user(user).where(id: current)
    else
      include_deleted ? for_user(user).toppest(type) : for_user(user).toppest(type).undeleted
    end
    options(user, array, categories, 0, include_deleted)
    array.compact
  end

  def self.options(user, array, categories, labels, include_deleted)
    return nil if categories.empty?
    categories.each do |parent|
      array << [LABEL*labels + parent.name, parent.id, parent.description]
      sub_categories = include_deleted ? parent.children.for_user(user) : parent.children.undeleted.for_user(user)
      options(user, array, sub_categories, labels + 1, include_deleted)
    end
  end

  def balance
    self.line_items.map(&:balance).map(&:to_f).sum
  end

  def remove_allowed?
    errors.add(:base, "You cannot delete a #{self.name} category that has a sub-category.") unless self.all_childen_deleted?
    errors.add(:base, "You cannot delete a #{self.name} category when there are unpaid line items that belong to it.") if self.balance != 0
    errors[:base].empty?
  end

  def delete
    update_attributes(deleted_at: Time.now)
  end

  def undelete
    update_attributes(deleted_at: nil) if can_be_undelete?
  end

  def deleted?
    deleted_at.present?
  end

  def can_be_undelete?
    parent.nil? || !parent.deleted?
  end

  def all_childen_deleted?
    children.all?(&:deleted?)
  end

end
