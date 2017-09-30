module Edi
  class LogsController < ApplicationController
    def show
      @edi_log = Edi::Log.find(params[:id])
      @error = @edi_log.error
      @message = @edi_log.message
    end

    def index
      @edi_logs = Edi::Log.includes([ { edi_exchanges: [:container, :invoice] }, :customer]).order("id DESC").page(params[:page])
    end

    def incomplete
      @containers = Container.incomplete.page(params[:page])
    end
  end
end