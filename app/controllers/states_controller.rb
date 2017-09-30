class StatesController < ApplicationController
  active_tab "US States"
  layout "quote_engines"

  def user_id
    if params[:format] == 'xml'
      authenticate_or_request_with_http_basic do |email, password|
        session[:uid] = User.authenticate(email, password).try(:id)
      end
    else
      super
    end
  end

  def index
    @states = State.all

    respond_to do |format|
      format.xml { render :xml => @states.to_xml}
      format.html
    end
  end
end
