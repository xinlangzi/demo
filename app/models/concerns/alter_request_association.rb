module AlterRequestAssociation
  extend ActiveSupport::Concern

  def has_alter_request?(attr)
    AlterRequest.exists?(self, attr)
  end

  def alter_request_at(attr)
    alter_requests.at(attr)
  end

  def add_alter_request(user, attr)
    alter_requests.find_or_create_by(attr: attr.to_s).update(user: user)
  end

  module ClassMethods

    def has_many_alter_requests(attr_roles={})
      has_many :alter_requests, as: :alter_requestable, dependent: :destroy

      after_update  do
        user = User.authenticated_user
        attr_roles.slice(*changed.map(&:to_sym)).each do |attr, roles|
          if user.has_role?(*roles)
            add_alter_request(user, attr)
          else
            alter_requests.find_by(attr: attr.to_s).try(:destroy)
          end
        end if user
      end
    end
  end
end
