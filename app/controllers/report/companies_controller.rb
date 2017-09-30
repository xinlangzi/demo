class Report::CompaniesController < Report::BasesController

  POST_MAILING = {
    "Name" => "name",
    "Address" => "address_streets",
    "City" => "address_city",
    "State" => "state",
    "Zip" => "zip_code"
  }

  def index
    @companies = crud_class.active
    respond_to do |format|
      format.csv{
        data = crud_class.csv(@companies, POST_MAILING)
        send_data(data, type: 'text/csv; charset=utf-8; header=present', filename: "#{crud_class.to_s}-#{Date.today}.csv")
      }
    end
  end

  def crud_class
    self.class.to_s.gsub('Controller', '').singularize.demodulize.constantize
  end
end
