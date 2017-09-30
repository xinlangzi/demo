class DriversController < ApplicationController

  def search
    @truckers = Trucker.active
    respond_to do |format|
      format.html
    end
  end

  def summary
    driver_pane_data
    respond_to do |format|
      format.html{
        render partial: 'summary'
      }
      format.js
    end
  end

  def assign
    expire_avail_stats
    send("assign_to_#{params[:target]}")
  end

  def vacation
    Vacation.toggle(params[:id], params[:date])
    expire_avail_stats
    ActionCable.server.broadcast "driver_pane", { action: 'reload', date: params[:date] }
    respond_to do |format|
      format.js{ head :ok }
    end
  end

  def cancel
    @operation = Operation.find(params[:iid])
    @container = @operation.container
    params[:date] = @operation.actual_appt.to_s
    @operation.cancel_driver
    expire_avail_stats
    respond_to do |format|
      format.js{
        if @operation.errors.empty?
          ActionCable.server.broadcast "driver_pane", { action: 'reload', date: params[:date] }
          ActionCable.server.broadcast "container", { action: 'refresh', id: @container.id }
          head :ok
        else
          render "operations/reload"
        end
      }
    end
  end

  def locate
    @trucker = Trucker.find(params[:id])
    respond_to do |format|
      format.html do |html|
        html.none { render layout: 'blank'}
      end
      format.json{ render json: @trucker.locations.last.to_h }
    end
  end

  def info
    @trucker = Trucker.find(params[:id])
    respond_to do |format|
      format.html { render layout: 'blank' }
    end
  end

  private

  def assign_to_operation
    trucker = Trucker.find(params[:tid])
    @operation = Operation.find(params[:id])
    @container = @operation.container
    @operation.assign(trucker)
    respond_to do |format|
      format.js{
        if @operation.errors.empty?
          ActionCable.server.broadcast "driver_pane", { action: 'reload', date: params[:date] }
          ActionCable.server.broadcast "container", { action: 'refresh', id: @container.id }
          head :ok
        else
          render "operations/reload"
        end
      }
    end
  end

  def assign_to_container
    trucker = Trucker.find(params[:tid])
    @container = Container.find(params[:id])
    @container.assign(trucker)
    respond_to do |format|
      format.js{
        ActionCable.server.broadcast "driver_pane", { action: 'reload', date: params[:date] }
        ActionCable.server.broadcast "container", { action: 'refresh', id: @container.id }
        head :ok
      }
    end
  end
end
