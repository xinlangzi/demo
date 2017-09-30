class RightsController < ApplicationController
  
  def show
    @right = Right.find(params[:id])
    @roles = @right.roles
    
  end
  
  def edit
    @right = Right.find(params[:id])
    @roles = Role.all
    
  end
  
  def update
    @right = Right.find(params[:id])
    @right.role_ids = params[:right][:role_ids]
    redirect_to @right
  end
end
