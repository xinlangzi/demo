class TaskCommentsController < ApplicationController

  before_action :build_params, only: [:create, :update]

  def popup
    @container = Container.find(params[:container_id])
    @task_comment = @container.find_or_init_task_comment(params[:container_task_id])
    render layout: false
  end

  def show
    @task_comment = TaskComment.find(params[:id])
    render layout: false
  end

  def create
    @task_comment = TaskComment.create(secure_params)
    render template: "task_comments/commented"
  end

  def update
    @task_comment = TaskComment.find(params[:id])
    @task_comment.update_attributes(secure_params)
    render template: "task_comments/commented"
  end

  private
    def build_params
      params[:task_comment][:to_check] = params[:commit].downcase == 'check'
    end

    def secure_params
      params.require(:task_comment).permit(:container_id, :container_task_id, :content, :to_check)
    end
end
