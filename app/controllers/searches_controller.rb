class SearchesController < ApplicationController

  def invoices
    @search = Invoice.search({ number_eq: params[:keyword] })
    @invoices = @search.result
    respond_to do |format|
      format.json{
        render json: json_for_autocomplete(@invoices, params[:term], ['url', 'icon'])
      }
    end
  end

  def companies
    @search = Company.viewable_by(current_user).search({ name_or_email_cont: params[:keyword] })
    @companies = @search.result
    respond_to do |format|
      format.json{
        render json: json_for_autocomplete(@companies, params[:term], ['url', 'icon'])
      }
    end
  end

end
