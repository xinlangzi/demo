class DocsController < ApplicationController

  def search
    respond_to do |format|
      format.html
      format.json{
        @images = Image.j1s_uploaded_by(current_user, params)
        render json: @images.map(&:to_h)
      }
      format.js{
        @images = J1s.by_operations(params[:q]).page(params[:page]).per(9)
        @trucker = Trucker.find(params[:q][:trucker_id]) rescue nil
      }
    end
  end

  def containers
    @q = params[:q].remove_empty
    if @q.blank?
      @containers = Container.none
    else
      @q[:trucker_id_eq] = params[:trucker_id]
      @search = Container.search(@q)
      @containers = @search.result.order("appt_date DESC")
                            .page(params[:page]).per(5)
                            .includes(:customer, operations: [:operation_type, :company, :trucker])
    end
  end

  def index
    @trucker = Trucker.find(params[:driver_id]) rescue nil
    if @trucker
      @images = Image.by_user(@trucker).j1s.non_approved
      @j1s = J1s.pending(@trucker)
    end
    respond_to do |format|
      format.html{
        ids = Trucker.active.pluck(:id)
        @missings = J1s.number_of_missing.count_by(&:owner_id)
        @pendings = Image.pending_j1s.count_by(&:user_id) # some truckers are inactive
        @truckers = Trucker.where(id: (ids + @pendings.keys).uniq)
      }
      format.js
    end
  end

  def new
    @image = Image.new(secure_params)
    respond_to do |format|
      format.html{ render layout: params[:layout] if params[:layout] }
    end
  end

  def create
    respond_to do |format|
      format.json{
        begin
          @next = J1s.next_missing(current_user, params[:name]) rescue nil
          save_multiple_files!
          message = "You uploaded #{params[:files].to_h.size} picture(s) successfully."
          case params[:target]
          when /stops/
            js = "J1s.reload();CloseAjaxPopup()"
            render json: { message: message, js: js }, status: :created
          when /j1s/
            if @next
              url = new_doc_path(
                image: {
                  imagable_type: @next.object.class.table_name.classify,
                  imagable_id: @next.object.id,
                  column_name: @next.column_name
                }, layout: 'popup', target: 'j1s', name: @next.to_s
              )
              js = "J1s.reload();CloseAjaxPopup();OpenAjaxPopup('#{url}')"
            else
              js = "J1s.reload();CloseAjaxPopup()"
            end
            render json: { message: message, js: js }, status: :created
          else
            js = "CloseAjaxPopup()"
            render json: { message: message, js: js }, status: :created
          end
        rescue => ex
          render json: [ex.message], status: :unprocessable_entity
        end
      }
    end

  end

  def show
    @image = Image.includes(:imagable).find_by(uuid: params[:id])
    respond_to do |format|
      format.html{ head :ok }
      format.js
    end
  end

  def update
    @image = Image.find_by(uuid: params[:id])
    @success = @image.update(secure_params)
    respond_to do |format|
      format.js
    end
  end

  def destroy
    begin
      @image = Image.delete_by!(params[:id], current_user)
    rescue => ex
      @error = ex.message
    end
    respond_to do |format|
      format.js
      format.json{
        if @error
          render json: @error, status: :unprocessable_entity
        else
          render json: { message: 'Image was deleted successfully.' }, status: :ok
        end
      }
    end
  end

  def assign
    @success = false
    Image.transaction do
      @images = Image.where(uuid: params[:ids].map(&:strip))
      @images.each do |image|
        image.update!(secure_params)
        image.approve!
      end
      @success = true
    end
  end

  def approve
    @image = Image.find_by(uuid: params[:id])
    @image.approve!
    respond_to do |format|
      format.js
    end
  end

  def reject
    @image = Image.find_by(uuid: params[:id])
    @image.reject!(secure_params[:comment])
    respond_to do |format|
      format.js
    end
  end

  def review
    case params[:nav]
    when /doc/
      @image = Image.includes(:imagable).find_by(uuid: params[:id])
    when /day_log/
      @date = params[:date].to_date
      @trucker = Trucker.find(params[:trucker_id])
      @day_logs = @trucker.day_logs.range(@date, @date)
    else
      @image = Image.includes(:imagable).find_by(uuid: params[:id])
      @date = @image.operation_time.to_date
      @trucker = Trucker.find(params[:trucker_id])
      @day_logs = @trucker.day_logs.range(@date, @date)
    end
    respond_to do |format|
      format.js
    end
  end

  private
    def save_multiple_files!
      params[:files].permit!
      @images = (params[:files]||{}).values.map do |file|
        image = Image.new(secure_params)
        image.status = :pending
        image.file = file
        image.user = current_user
        image.save!
      end
    end

    def secure_params
      attrs = [:column_name, :imagable_id, :imagable_type, :comment]
      params.require(:image).permit(attrs).tap do |whitelisted|
        whitelisted[:tag_list] = params[:image][:tag_list] rescue nil
      end
    end
end
