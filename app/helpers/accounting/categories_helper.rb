module Accounting
  module CategoriesHelper

    def delete_undelete_link(id)
      category = Category.find(id)
      if category.deleted?
        link_to "Undelete", undelete_accounting_category_path(category, :type => params[:type]), :data => {:confirm => "Are you sure to undelete #{category.name}?"}
      else
        link_to "", accounting_category_path(category), remote: true, method: :delete, data: {confirm: "Are you sure to delete #{category.name}?"}, class: 'fa fa-trash'
      end
    end

    def status(id)
      category = Category.find(id)
      if category.deleted?
        "Deleted"
      else
        "Active"
      end
    end

  end
end