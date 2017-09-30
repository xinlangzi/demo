class ReceivableQuotesController < ApplicationController
  include ContainerFilters

  before_action :deal_with_appt_time, only: [:cache]

  def cache
    session[:cached_params] = params
    head :ok
  end

  def query
    init_container
    @rq = ReceivableQuote.new(container: @container)
    if @rq.valid?
      @customer_quotes = @rq.customer_quotes.page(params[:page]).per(5)
      @stack_quotes = @rq.stack_quotes.page(params[:page]).per(5)
    end
  end

  def create
    init_container
    @rq = ReceivableQuote.new(secure_params)
    @rq.build_charges
  end

  private
    def init_container
      if (params[:auto_save] || params[:preview]).to_boolean
        @container = Container.for_user(current_user).find(params[:container_id])
      else
        cached_params = session[:cached_params]
        const = cached_params[:order_type].constantize
        @container = const.find(cached_params[:container][:id]) rescue const.new
        @container.hub||= current_hub
        @container.attributes = cached_params[:container].try(:permit!) || {}
        @container.payable_container_charges.update_collection(cached_params[:payable_container_charges].try(:permit!) || {})
        @container.receivable_container_charges.update_collection(cached_params[:receivable_container_charges].try(:permit!) || {})
      end
    end

    def secure_params
      {
        container: @container,
        target_id: params[:target_id],
        charge_ids: params[:charge_ids],
        save_mode: params[:auto_save].to_boolean
      }
    end
end
