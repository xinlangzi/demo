class PaperTrailsController < ApplicationController

  def index
    @item_types = PaperTrail::Version.select(:item_type).distinct.map(&:item_type).sort
    @search = PaperTrail::Version.desc.search(params[:q])
    @versions = @search.result.page(params[:page])
  end

end
