class ContainerSelectorsController < ApplicationController

  helper ContainersHelper
  before_action :set_container

  def new
    @found = session[:container_selectors].include?(@container.uuid)
    session[:container_selectors] << @container.uuid unless @found
  end

  def destroy
    session[:container_selectors].delete(@container.uuid)
  end

  private
    def set_container
      session[:container_selectors]||= []
      @container = Container.find(params[:id])
    end

end
