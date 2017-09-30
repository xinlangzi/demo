class Mobiles::UsersController < ApplicationController

  def login
    try_to_login
    respond_to do |format|
      format.json{
        if current_user
          current_user.refresh_mobile_token unless params[:token].present?
          current_user.register_device(params[:device])
          Mobile::Status.record(params[:device], {
            platform: params[:platform],
            version_name: params[:version_name],
            logged_at: Time.now,
            authed: true
          })
          render status: :ok, json: { token: current_user.mobile_token }
        else
          Mobile::Status.record(params[:device], {
            platform: params[:platform],
            version_name: params[:version_name],
            authed: false
          })
          render status: 401, json: { message: 'Invalid user/password combination.' }
        end
      }
    end
  end

  def logout
    respond_to do |format|
      format.json{
        Mobile::Status.record(params[:device], { authed: false })
        render status: :ok, json: {}
      }
    end
  end

  def retrieve_password
    @info = User.request_set_password(params)
    respond_to do |format|
      format.json{
        if @info == User::SET_PASSWORD_REQUEST_APPROVED
          render status: :ok, json: { message: @info }
        else
          render status: 401, json: { message: @info }
        end
      }
    end
  end

  private
    def try_to_login
      if params[:token]
        session[:uid] = User.auth_by_token(params[:token]).try(:id)
      else
        params[:user]||={}
        params[:user][:email]||= params[:email]
        params[:user][:password]||= params[:password]
        @user = User.new(user_params)
        session[:uid] = @user.try_to_login(request).try(:id)
      end
    end

    def user_params
      params.require(:user).permit(:email, :password)
    end
end
