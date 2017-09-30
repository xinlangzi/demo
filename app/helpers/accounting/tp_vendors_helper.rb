#encoding: utf-8
module Accounting
	module TpVendorsHelper
		def column_list
			dict = super
			dict.insert(3, 'Social Security No.', lambda{|c| c.ssn})
	    dict.insert(4, '1099', lambda{|c| c.onfile1099 ? "✔" : ""})
	    dict
	  end

	  def detailed_column_list
	  	dict = super
	  	dict.insert(3, 'Social Security No.', lambda{|c| c.ssn})
	    dict.insert(4, '1099', lambda{|c| c.onfile1099 ? "✔" : ""})
	  	dict
	  end
	end
end