class ImagesController < ApplicationController

  skip_before_action :check_authentication, :check_authorization, only: [:delete]

  def show
    @image = Image.find_by(uuid: params[:id])
    respond_to do |format|
      format.html
      format.js
      format.pdf{
        if @image.file.image?
          html = render_to_string(template: 'images/show', layout: 'blank', formats: [:pdf])
          pdf = Wisepdf::Writer.new.to_pdf(html, { page_size: "letter" })
          send_data(pdf, filename: "#{@image.uuid}.pdf", type: :pdf)
        else
          io = open(@image.file.url) rescue open(@image.file.path)
          send_data(io.read, type: :pdf)
        end
      }
    end
  end

  def new
    @image = Image.new(secure_params)
    respond_to do |format|
      format.html
      format.html.phone{ render layout: 'application' }
    end
  end

  def create
    options = secure_params.to_h
    @image = Image.new(options.reverse_merge(file: params[:file]))
    @image.user = current_user
    @image.status = current_user.is_admin? ? :approved : :pending
    respond_to do |format|
      if @image.save
        cache_image
        format.html{ redirect_to @image, notice: 'saved' }
        format.json{ render status: :created }
      else
        format.html{ render :new }
        format.json{ render json: @image.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    begin
      @image = Image.find_by(uuid: params[:id])
      if @image.can_write?(current_user)
        if @image.destroy
          flash[:notice] = 'Image was deleted'
          render template: 'images/deleted'
          return
        else
          render :text => 'No such image'
        end
      else
        flash[:notice] = "You can not delete this image."
        redirect_to action: 'show'
      end
    rescue => ex
      render action: 'show'
    end
  end

  def delete
    @image = Image.pending.find_by(uuid: params[:id])
    raise ActiveRecord::RecordNotFound unless @image
    render template: 'images/deleted' if @image.destroy
  end

  def approve
    @image = Image.find_by(uuid: params[:id])
    @image.approve!
    respond_to do |format|
      format.html{
        redirect_to @image
      }
    end
  end

  private

    def secure_params
      params.require(:image).permit(
        :column_name, :file, :imagable_id, :imagable_type
      ) rescue {}
    end

    def cache_image
      if key = params[:cache].try(:to_sym)
        (session[key]||=[]).tap do |s|
          s << @image.id
        end
      end
    end
end
