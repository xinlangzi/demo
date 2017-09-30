class Accounting::LineItemsController < ApplicationController
	before_action :accounts_type

	def new
		@invoice = "Accounting::#{@accounts_type}Invoice".constantize.new
		@invoice.line_items.build
    respond_to do |format|
      format.js
    end
	end

	private
  # returns Payable or Receivable string
    def accounts_type
      @accounts_type = self.class.to_s.gsub('LineItemsController', '').gsub(/Accounting::/, '')
    end
end