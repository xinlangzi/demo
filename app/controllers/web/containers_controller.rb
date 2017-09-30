class Web::ContainersController < ApplicationController
  skip_before_action :check_authentication, :check_authorization

  before_action :set_container, except: [:pods, :elink]

  layout 'visitor'

  def charges
    respond_to do |format|
      format.html
      format.js{
        @container = @customer.containers.search(container_no_eq: params[:container_no].strip).result.last
      }
    end
  end

  def pickup
    respond_to do |format|
      format.html{
        begin
          if request.get?
            @container.email_to = @container.customers_employee.email
          else
            updated = @container.save_pickup_info!(secure_pickup)
            if updated
              flash[:notice] = "The pickup information was saved and emailed to you."
            else
              flash[:notice] = "The pickup information was not changed."
            end
          end
        rescue => ex
          flash[:error] = ex.message
        end
      }
      format.js{
        flash.clear
        @container = @customer.containers.search(container_no_eq: params[:container_no].strip).result.last
      }
    end
  end

  def pods
    @containers = Container.for_email(params[:email]).where(container_no: params[:container_no])
  end

  def elink
    @container = Container.for_email(params[:email]).find(params[:id])
    OrderMailer.delay.notify_elink_to_customer(@container.id, params[:email])
  end

  private
    def set_container
      @container = Container.find_by(uuid: params[:id])
      raise ActiveRecord::RecordNotFound unless @container
      @customer = @container.customer
    end

    def secure_pickup
      params.require(:container).permit(:pickup_no, :rail_lfd, :email_to)
    end
end
