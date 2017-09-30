class StreetTurnsController < ApplicationController

  def new
    @street_turn = StreetTurn.new(source_id: params[:id])
    @source = @street_turn.source
    authorize @source, :edit?
  end

  def create
    @saved = false
    @street_turn = StreetTurn.new(secure_params)
    unless params[:changed]
      @street_turn.save!
      @saved = true
    end
  rescue => ex
    @street_turn.add_error(ex.message)
  end

  def unlink
    @street_turn = StreetTurn.new(source_id: params[:id])
    @street_turn.unlink!
  end

  private

    def secure_params
      params.require(:street_turn).permit(:source_id, :type, :dest_id, :yard_id)
    end

end
