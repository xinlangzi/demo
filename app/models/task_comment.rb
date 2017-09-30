class TaskComment < ApplicationRecord
  has_paper_trail ignore: [:id, :created_at, :updated_at, :container_id]

  attr_accessor :to_check

  belongs_to :container
  belongs_to :container_task

  validates :container_id, :container_task_id, presence: true

  after_save :check_task

  PAPER_TRAIL_TRANSLATION ={
    "container_task_id"     => ->(id){ ContainerTask.find(id).to_s }
  }

  def is_checked?
    container.task_ids.include?(self.container_task_id)
  end

  private
    def check_task
      container.toggle_task(self.container_task_id) if to_check
    end
end
