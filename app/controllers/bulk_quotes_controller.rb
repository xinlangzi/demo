class BulkQuotesController < ApplicationController

  active_tab "Bulk Quotes"

  layout 'quote_engines'

  def index
    @bulk_quotes = BulkQuote.all
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @bulk_quote = BulkQuote.new(secure_params)
    @bulk_quote.user = current_user
    respond_to do |format|
      if @bulk_quote.save
        format.html{redirect_to bulk_quotes_path, notice: 'Bulk Quote was successfully created.' }
      else
        format.html { render :action => "index" }
        format.json { render json: @bulk_quote.errors, status: :unprocessable_entity }
      end
    end
  end

  def run
    @bulk_quote = BulkQuote.find(params[:id])
    @bulk_quote.delay_quoting
    respond_to do |format|
      format.html {redirect_to bulk_quotes_path}
    end
  end

  def destroy
    @bulk_quote = BulkQuote.find(params[:id])
    @bulk_quote.destroy
    respond_to do |format|
      format.js
    end
  end

  private

  def secure_params
    attrs = [:csv, :base_ratio]
    params.require(:bulk_quote).permit(attrs)
  end
end