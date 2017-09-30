class ExtraDrayagesController < ApplicationController
  active_tab "Extra Drayages"
  layout "quote_engines"

  def index
    @styles = ExtraDrayage.styles_by_ssline_and_rail_road
  end

  def create
    ExtraDrayage.build(secure_params.to_h)
    head :ok
  end

  private

  def secure_params
    attrs = [
      :ssline_id, :rail_road_id, styles: []
    ]
    params.require(:extra_drayage).permit(attrs)
  end
end
