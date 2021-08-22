module DatoAPI

	class Resources < Handler

		def has_data?(record)
			return record.title.present?
		end

	end

end