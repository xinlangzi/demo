class Mobiles::LocationsController < ApplicationController
  skip_before_action  :cowner,
                      :set_request_variant,
                      :check_authentication,
                      :check_authorization,
                      :check_system_settings

  respond_to :json

  def index
    head :ok
  end

  def create
    begin
      user = User.auth_by_token(params[:token])
      data = params[:data]
      case true
      when user.present?
        Mobile::Status.record(params[:device], { located_at: Time.now })
        Location.store!(user, data)
        render status: :ok, json: {}
      when data.size > Location::MAX_LOCATIONS
        render status: :ok, json: {} # render OK to clear array
      else
        Mobile::Status.record(params[:device], { authed: false })
        render status: 401, json: { message: "Invalid user/password combination." }
      end
    rescue =>ex
      render status: 400, json: { message: ex.message }
    end
  end
end
