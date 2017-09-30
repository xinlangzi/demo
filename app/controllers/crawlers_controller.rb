class CrawlersController < ApplicationController
  def user_id
    if params[:format] == 'xml'
      authenticate_or_request_with_http_basic do |email, password|
        session[:uid] = User.authenticate(email, password).try(:id)
      end
    else
      super
    end
  end

  def show
    respond_to do |format|
      @crawler = Crawler.first

      format.xml { render :xml => @crawler.xml_attributes.to_xml}
    end
  end

  def index
    respond_to do |format|
      robots = Crawler.all
      @crawlers = Array.new
      robots.each{|r| @crawlers << r.xml_attributes}

      format.xml { render :xml => @crawlers.to_xml}
    end
  end
end
