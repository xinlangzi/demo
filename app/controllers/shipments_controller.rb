class ShipmentsController < ApplicationController

  def email
    @shipment = Shipment.new(params[:shipment])
    if params[:changed].blank?
      begin
        @shipment.file_ids = session[@shipment.doc_key]
        @container = @shipment.container
        @shipment.email!
        flash[:notice] = "The shipment status of this container was emailed out successfully!"
        session[@shipment.doc_key] = nil
      rescue => ex
        @error = ex.message
      end
    end
  end

end
