class CheckTemplatesController < ApplicationController

  def index
    @check_templates = CheckTemplate.all
  end

  def show
    @check_template = CheckTemplate.find(params[:id])
    respond_to do |format|
      format.html
      format.slim {
        send_data(@check_template.rtf, filename: @check_template.name, disposition: 'attachment')
      }
    end
  end

  def new
    @check_template = CheckTemplate.new
  end

  def create
    @check_template = CheckTemplate.new(secure_params)
    @check_template.admin_id = current_user.id
    respond_to do |format|
      if @check_template.save
        flash[:notice] = 'CheckTemplate was successfully created.'
        format.html { redirect_to(@check_template) }
        format.xml  { render :xml => @check_template, :status => :created, :location => @check_template }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @check_template.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /check_templates/1/edit
  def edit
    @check_template = CheckTemplate.find(params[:id])
  end

  def update
    @check_template = CheckTemplate.find(params[:id])
    respond_to do |format|
      if @check_template.update_attributes(secure_params)
        format.html { redirect_to(check_templates_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @check_template.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /check_templates/1
  # DELETE /check_templates/1.xml
  def destroy
    @check_template = CheckTemplate.find(params[:id])
    @check_template.destroy
    redirect_to check_templates_url
  end

  private
   def secure_params
    attrs = [:name, :rtf, :as_default]
    params.require(:check_template).permit(attrs)
   end
end
