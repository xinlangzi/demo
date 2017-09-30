class OperationPolicy < ApplicationPolicy

  def edit?
    acceesible_hub?
  end

  private
    def acceesible_hub?
      Hub.for_user(user).pluck(:id).include?(record.hub_id)
    end

end
