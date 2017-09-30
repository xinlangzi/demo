class SqlController < ApplicationController

  def show
    @objects = Sql.find(params[:id]).execute
    respond_to do |format|
      format.js{ render template: params[:tmpl] }
    end
  end
end