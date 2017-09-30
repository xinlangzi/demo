class OwnersController < ApplicationController

  def edit
    @owner = Owner.itself
  end

  def update
    @owner = Owner.itself
    @owner.attributes = secure_params
    @owner.logo = secure_params[:logo] if secure_params[:logo]
    if @owner.valid?
      @owner.save
      redirect_to my_account_url, notice: 'Information on owner has been successfully saved!'
    else
      render :edit
    end
  end


  private
    def secure_params
      attrs = [
        :logo, :name, :contact_person, :email,
        :web, :phone, :phone_extension, :phone_mobile, :fax,
        :address_street, :address_street_2, :address_city, :address_state_id, :zip_code,
        :lat, :lng, :quickbooks_integration, :comments
      ]
      params.require(:owner).permit(attrs)
    end
end
