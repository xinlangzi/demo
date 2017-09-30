class AlterRequestsController < ApplicationController

  def approve
    begin
      @alter_request = AlterRequest.find(params[:id])
      @alter_request.approve!
    rescue => ex
      @error = ex.message
    end
  end

end
