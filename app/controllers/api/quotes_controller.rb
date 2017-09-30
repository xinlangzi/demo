class Api::QuotesController < Api::BaseController
  def create
    respond_to do |format|
      format.json { render json: Api::Quote.create(params) }
    end
  end
end
