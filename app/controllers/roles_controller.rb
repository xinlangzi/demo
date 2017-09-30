class RolesController < ApplicationController

  respond_to :html, only: [:create]

  def index
    @roles = Role.all
  end

  def show
     redirect_to :action => 'index'
  end

  def new
    @role = Role.new
    render :template => 'roles/new'
  end

  def create
    @role = Role.new(role_params)
    @role.save
    respond_with @role, location: ->{ roles_path }
  end

  def edit
    @role = Role.find(params[:id])
    @rights = Right.tree
    if @role.name.humanize == "Customer"
      @users = CustomersEmployee.all
    elsif @role.name.humanize == "Trucker"
      @users = Trucker.all
    else
      @users = Admin.active
    end
    @users = @users.order("name ASC")
  end

  def edit_action_names
    @rights = Right.tree
  end

  def update_action_names
    params[:right].each do |key, value|
      @right = Right.find(key)
      @right.update_attributes(value)
    end
    redirect_to :action => 'index'
  end

  def update_all
    @role = Role.find(params[:role][:id])
    rights_array = []
    users_array = []

    params[:right].each do |id, selected|
      rights_array << Right.find(id) if selected == "1"
    end

    params[:user].each do |id, selected|
      users_array << User.find(id) if selected == "1"
    end

    @role.rights = rights_array
    @role.users = users_array
    Header.all.map(&:touch)

    redirect_to :action => "index"
  end

  def destroy
    @role = Role.find(params[:id])
    @role.destroy

    respond_to do |format|
      format.html { redirect_to(roles_url) }
      format.xml  { head :ok }
    end
  end

  private

  def role_params
    attrs = [:name]
    params.require(:role).permit(attrs)
  end

end
