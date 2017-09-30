class HeadersController < ApplicationController

	def toggle
		@header = Header.find(params[:id])
		@header.toggle(params[:key])
	end
end