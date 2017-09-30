class ContainerTasksController < ApplicationController

  after_action :expire_caches, only: [:create, :update, :destroy]

  def index
    @container_tasks = ContainerTask.all
  end

  def new
    @container_task = ContainerTask.new
  end

  def create
    @container_task = ContainerTask.new(secure_params)
    respond_to do |format|
      if @container_task.save
        flash[:notice] = "#{@container_task.name} was successfully created."
        format.html{redirect_to container_tasks_path}
      else
        format.html{render action: "new"}
      end
    end
  end

  def edit
    @container_task = ContainerTask.find(params[:id])
  end

  def update
    @container_task = ContainerTask.find(params[:id])
    respond_to do |format|
      if @container_task.update_attributes(secure_params)
        flash[:notice] = "#{@container_task.name} was successfully updated."
        format.html{redirect_to container_tasks_path}
      else
        format.html{render action: "edit"}
      end
    end
  end

  def destroy
    @container_task = ContainerTask.find(params[:id])
    respond_to do |format|
      if @container_task.destroy
        flash[:notice] = "#{@container_task.name} was successfully deleted."
        format.html{redirect_to container_tasks_path}
      end
    end
  end

  private
  def expire_caches
    # see container_tasks/_check_list.html.slim
    expire_fragment('import-receivable')
    expire_fragment('import-payable')
    expire_fragment('import-others')
    expire_fragment('export-receivable')
    expire_fragment('export-payable')
    expire_fragment('export-others')
  end

  def secure_params
    attrs = [:name, :ctype, :acct_type]
    params.require(:container_task).permit(attrs)
  end

end