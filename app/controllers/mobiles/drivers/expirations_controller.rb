class Mobiles::Drivers::ExpirationsController < ApplicationController

  def index
    respond_to do |format|
      format.html{ render layout: false }
    end
  end

  def new
    @image = Image.new(secure_params)
    respond_to do |format|
      format.html{ render layout: false }
    end
  end

  def create
    respond_to do |format|
      format.json{
        begin
          file = file_params.values.last
          @image = Image.build(secure_params) do |image|
            image.file = file
            image.user = current_user
            image.status = :pending
          end
          message = "You uploaded the captured picture successfully."
          render json: { message: message, js: "CloseAjaxPopup();DriverExpiration.reload()" }, status: :created
        rescue => ex
          render json: [ex.message], status: :unprocessable_entity
        end
      }
    end
  end

  private

    def secure_params
      params.require(:image).permit(:column_name, :imagable_id, :imagable_type)
    end

    def file_params
      params.require(:files).permit! rescue {}
    end
end
