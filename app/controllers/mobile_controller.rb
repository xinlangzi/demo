class MobileController < ApplicationController
  skip_before_action :check_authentication, :check_authorization

  def index
  end
end
