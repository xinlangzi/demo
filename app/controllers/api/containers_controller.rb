class Api::ContainersController < Api::BaseController
  respond_to :json

  def index
    render json: Api::Container.filter(params)
  end

end
