class PicturesController < ApplicationController

  def rotate
    @picture = Picture.new(secure_params)
    @picture.rotate!
    respond_to do |format|
      format.js
      # {
      #   render template: params[:tmpl] || 'pictures/rotate'
      # }
    end
  end

  private

    def secure_params
      params.require(:picture).permit(:id, :klass, :method)
    end

end
