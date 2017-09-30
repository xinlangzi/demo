class Web::ShipmentsController < ApplicationController
  skip_before_action :check_authentication, :check_authorization

  layout 'visitor'

  def index
    @containers = Container.none
    eager_loads = { operations: [:operation_type, { company: :address_state } ] }
    case true
    when params[:id].present?
      ids = params[:id].split(/,/).map(&:strip).reject(&:blank?)
      @containers = Container.where(uuid: ids).includes(eager_loads)
    when params[:ids].present?
      nos = params[:ids].split(/\W/).map(&:strip).reject(&:blank?)
      @containers = Container.tracking(nos).includes(eager_loads) unless nos.blank?
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

end
