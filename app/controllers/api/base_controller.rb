class Api::BaseController < ApplicationController
  skip_before_action :check_authentication, :check_authorization
end