class Accounting::CategoriesController < ApplicationController

  # GET /accounting_categories
  # GET /accounting_categories.xml
  def index
    @category = Accounting::Category.new(feature: params[:type])
    @categories = Accounting::Category.toppest(params[:type])
    respond_to do |format|
      format.html
      format.xml  { render :xml => @categories }
    end
  end

  # # GET /accounting_categories/new
  # # GET /accounting_categories/new.xml
  def new
    @category = Accounting::Category.new(feature: params[:type])
    respond_to do |format|
      format.js
    end
  end

  # # GET /accounting_categories/1/edit
  def edit
    @category = Accounting::Category.find(params[:id])
  end

  # POST /accounting_categories
  # POST /accounting_categories.xml
  def create
    @category = Accounting::Category.new(secure_params)
    respond_to do |format|
      if @category.save
        format.js{ flash[:notice] = 'Category saved successfully.' }
      else
        format.js{ render template: 'accounting/categories/new' }
      end

    end
  end

  # # PUT /accounting_categories/1
  # # PUT /accounting_categories/1.xml
  def update
    @category = Accounting::Category.find(params[:id])
    @success = @category.update_attributes(secure_params)
    flash[:notice] = 'Category was successfully updated.' if @success
    respond_to do |format|
      format.js
    end
  end

  # # DELETE /accounting_categories/1
  # # DELETE /accounting_categories/1.xml
  def destroy
    @category = Accounting::Category.find(params[:id])
    @success = @category.delete if @category.remove_allowed?
    flash[:notice] = 'Category was deleted.' if @success
    respond_to do |format|
      format.js
    end
  end

  def undelete
    type = params[:type]
    @category = Accounting::Category.find(params[:id])
    if @category.undelete
      redirect_to accounting_categories_path :type => type
    else
      flash[:notice] = 'Category cannot be undelete.'
      redirect_to accounting_categories_path :type => type
    end
  end

  private

  def secure_params
    params.require(:accounting_category).permit(
      :name, :description, :feature,
      :parent_id, :accounting_group_id,
      :for_container, :road_side_service, :acct_only
    )
  end
end
