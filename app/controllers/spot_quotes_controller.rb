class SpotQuotesController < ApplicationController
  active_tab "Quote History"
  layout "quote_engines"

  def index
    @search = SpotQuote.quoted.search(params[:q])
    @quotes = @search.result.page(params[:page])
  end

  def override
    @spot_quote = SpotQuote.find(params[:id]).override
  end

  def create
    @spot_quote = SpotQuote.new(secure_params)
    @spot_quote.save
  end

  def update
    @spot_quote = SpotQuote.find(params[:id])
    @spot_quote.update_attributes(secure_params)
  end

  def summary
    @spot_quote = SpotQuote.new(secure_params)
  end

  def review
    @search = SpotQuote.quoted.to_review.search(params[:q])
    @quotes = @search.result.page(params[:page])
    render layout: 'application'
  end


  def show
    @quote_engine = QuoteEngine.new
    @spot_quotes = SpotQuote.where(id: params[:id])
    render layout: "mail"
  end

  private
  def secure_params
    attrs = [
    	:add_rail, :base_rate_fee,
    	:cargo_weight, :chassis_dray, :chassis_fee, :comment, :container_size_id, :container_type_id, :customer_id,
    	:dest_address, :drop_pull, :drop_rate_fee,
    	:email_to, :expired_date, :free_text1, :free_text2, :fuel_amount, :gallon_price,
    	:hazardous, :instant_date, :live_load, :meters, :miles,
    	:operation_id, :original_id, :over1, :over2, :overrided_at,
    	:port_id, :preset, :private_comment, :q_free_text1, :q_free_text2,
    	:rail_road, :rail_road_id, :reefer_fee, :ssline_id, :start_address,
    	:toll_surcharge, :tolls, :tolls_fee, :triaxle, :user_id
    ]
    params.require(:spot_quote).permit(attrs)
  end
end
