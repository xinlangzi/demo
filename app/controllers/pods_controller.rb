class PodsController < ApplicationController

  before_action :set_container, only: [:new, :create, :show]

  def new
    @pod = Pod.init(@container)
    respond_to do |format|
      format.html{
        render template: @pod.persisted? ? 'pods/show' : 'pods/new'
      }
    end
  end

  def create
    @pod = @container.pods.build(secure_params)
    @pod.user = current_user
    @pod.intact||= false
    @pod.save
    respond_to do |format|
      if @pod.persisted?
        format.html{ redirect_to @container }
        format.json{ render json: { message: "POD was successfully uploaded to container #{@container.to_s}!" }, status: :created }
      else
        format.html{ render action: "new" }
        format.json{ render json: @pod.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def show
    @pod = @container.pods.find(params[:id])
    respond_to do |format|
      format.pdf{
        send_data(
          Wisepdf::Writer.new.to_pdf(render_to_string(template: 'pods/show', layout: 'pod', formats: [:html])),
          filename: "CID#{@container.id}-Signature.pdf",
          type: :pdf,
          disposition: 'inline'
        )
      }
    end
  end

  private
    def set_container
      @container = Container.for_user(current_user).find(params[:container_id])
    end

    def secure_params
      attrs = [:name, :email, :arrival_time, :departure_time, :seal_no, :intact, :measure, :exceptions, :signature_data]
      params.require(:pod).permit(attrs)
    end
end
