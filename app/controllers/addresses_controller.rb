class AddressesController < ApplicationController

	def incomplete
		@companies = [Consignee, Depot, Shipper, Terminal].collect{|klass| klass.incomplete_address.all}
	end

end