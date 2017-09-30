class LinkCodesController < ApplicationController

  layout 'quote_engines'

  def index
    @link_code = LinkCode.new
    @link_codes = LinkCode.all
    @bulk_quote = BulkQuote.find(params[:bulk_quote_id])
    respond_to do |format|
      format.js
    end
  end

  def create
    @bulk_quote = BulkQuote.find(params[:bulk_quote_id])
    @link_code = LinkCode.new(secure_params)
    @link_code.save
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @link_code = LinkCode.find(params[:id])
    @link_code.destroy
    respond_to do |format|
      format.js
    end
  end

  private

  def secure_params
    attrs = [:name, :rail_road_id, :additional_fee]
    params.require(:link_code).permit(attrs)
  end
end