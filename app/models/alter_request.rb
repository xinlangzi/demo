class AlterRequest < ApplicationRecord
  belongs_to :user, class_name: 'Company', foreign_key: :user_id
  belongs_to :alter_requestable, polymorphic: true, touch: true
  has_many :notifications, as: :notifiable
  validates :attr, presence: true
  validates :attr, uniqueness: { scope: [:alter_requestable_type, :alter_requestable_id] }

  def self.at(attr)
    where(attr: attr.to_s).first
  end

  def self.exists?(object, attr)
    object.alter_requests.where(attr: attr.to_s).exists?
  end

  def approve!
    AlterRequest.transaction do
      destroy!
      callback = "#{attr}_approved!".to_sym
      alter_requestable.send(callback) if alter_requestable.respond_to?(callback)
    end
  end

end
