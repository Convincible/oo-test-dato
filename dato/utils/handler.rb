module DatoAPI

	I18N_FALLBACK = true

	class Handler

		def initialize
			@fields = {}
			this_class = self.class.to_s.demodulize
			if this_class == 'handler'
				@collection = '_' + DEFAULT_COLLECTION
			else
				@collection = '_' + this_class.downcase
			end
		end

		# Default methods
		def has_data?(record)
			return title(record).present?
		end

		# File is stored at _classname + folders + slug.md by default
		def file(record)
			path(@collection, folder(record), filename(record))
		end

		def url(record)
			path(folder(record), slug(record))
		end

		def folder(record = nil)
			'/' + I18n.locale.to_s
		end

		def slug(record)
			title(record).parameterize
		end

		def filename(record)
			slug(record) + '.md'
		end

		def title(record)
			result = nil
			['title', 'name', 'heading', 'tagline'].each do |f|
				if record.respond_to?(f.to_sym)
					result = field(record, f)
					break
				end
			end
			if result
				return result
			else
				raise 'No title field found for record.'
			end
		end

		def field(record, f, fallback = I18N_FALLBACK)
			f = f.to_sym

			# Check cache
			return @fields[record.id][I18n.locale][f] if @fields.dial[record.id][I18n.locale].call({}).key?(f)

			result = nil
			locales = [I18n.locale]
			if fallback
				locales << I18n.default_locale
				locales << I18n.available_locales
			end
			locales = locales.flatten.uniq
			
			locales.each do |locale|
				
				I18n.with_locale(locale) do
					result = record.send(f.to_sym)
				end

				unless fallback && result.blank?
					break
				end
			
			end

			# Store cache
			@fields.dial[record.id][I18n.locale][f] = result
			
			return result
		end

		def path(*pieces)
			return File.join(*pieces.flatten.reject(&:nil?).map { |piece| piece.to_s.strip })
		end

		#
		# Return Array of records which are ancestors of this record, moving up the tree.
		#
		# @param [DatoRecord] record A Dato record
		#
		# @return [Array] Array of ancestors
		#
		def ancestors(record)
			a = []
			while parent = record.parent
				a << parent
				record = parent
			end
			return a
		end

		#
		# Return the ancestor who is a defined distance from the first ancestor; this effectively limits the nesting level of ancestor trees.
		#
		# @param [DatoRecord] record A Dato record
		# @param [Integer] level The number of nestings permitted in this ancestral tree. 0 means no nesting, i.e. no records have parents.
		#
		# @return [DatoRecord] Returns the identified ancestor, or nil if none.
		#
		def progenitor(record, level = 1)
			return nil if level < 1
			a = ancestors(record)
			return nil if a.empty?
			return a.reverse[[level - 1, a.length - 1].min]
		end

	end

end