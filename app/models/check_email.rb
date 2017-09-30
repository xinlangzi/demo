class CheckEmail
	@@warnings = []
	def self.filter(objs, field=:email, show_warnings=true)
		rets = []
		Array(objs).each do |obj|
			email = obj.send(field)
			if !email.blank?&&(email=~REGEX_EMAIL_VALIDATOR)
				rets << obj
			else
				@@warnings << [obj, field] if show_warnings
			end
		end
		rets.map(&field).join(',').split(',').map(&:strip).uniq
	end

	def self.warnings
		ret = @@warnings.uniq
		@@warnings = []
		ret
	end

	def self.warning?
		@@warnings.present?
	end
end
