module DatoAPI

	class << self
		attr_accessor :models, :model
	end

	#
	# Call Dato and store model data in @model
	#
	def self.get_models
		@models ||= [
			'home',
			'activities',
			'sectors',
			'regions',
			'projects',
			'case_studies',
			'people',
			'offices',
			'news'
		]
		@model ||= @models.map { |model|
			[model.to_sym, $dato.send(model.to_sym)]
		}.to_h
	end

	#
	# Get a standardised Hash representing an image from a Dato image field
	#
	# @param [Object] image A Dato image field returned from a record via the Dato API
	# @param [String] *attr The attributes of the image that the Hash should include
	#
	# @return [Hash] A Hash of attribute => value for the image, or empty Hash
	#
	def self.image(image, *attr)
		img = {}
		attr = ['url', 'alt', 'title'] if attr.empty?
		attr.each { |att|
			att = att.to_s.to_sym
			key = att
			case att
			when :url
				key = 'src'
			end
			if att == :url && !image.respond_to?(:url)
				if image.respond_to?(:path) && image.respond_to?(:imgix_url)
					img[key] = image.send(:imgix_url) + image.send(:path)
				end
			end
			img[key] = image.send(att) if image.respond_to?(att)
			img.delete(key) if img[key].blank?
		}
		#case img.size
		#when 0
		#	return {}
		#when 1
		#	return img[img.keys[0]]
		#else
		#	return img
		#end
		img
	end

	#
	# Get a standardised Hash representing a video from a Dato image field
	#
	# @param [Object] image A Dato image field returned from a record via the Dato API
	# @param [String] *attr The attributes of the video that the Hash should include
	#
	# @return [Hash] A Hash of attribute => value for the video, or empty Hash
	#
	def self.video(_video, *attr)
		vid = {}
		if (video = _video.to_hash) && video[:video]

			attr = ['m3u8', 'mp4', 'thumb'] if attr.empty?
			attr.map! { |a| a.to_s.to_sym }
			
			attr.each do |att|
				case att
				when :id
					vid[att] = video[:video][:mux_playback_id]
				when :framerate
					vid[att] = video[:video][:framerate]
				when :duration
					vid[att] = video[:video][:duration]
				when :m3u8
					vid[att] = video[:video][:streaming_url]
				when :mp4
					vid[att] = video[:video][:mp4_url]
				when :thumb
					vid[att] = video[:video][:thumbnail_url]
				else
					vid[att] = _video.send(att) if _video.respond_to?(att)
				end
				vid.delete(att) if vid[att].blank?
			end
		end
		vid
	end

	#
	# Get a standardised Hash representing SEO data from a Dato SEO field
	#
	# @param [Object] seo_obj A Dato SEO field returned from a record via the Dato API
	#
	# @return [Hash] A Hash of SEO attribute => value, or nil
	#
	def self.seo(seo_obj)
		seo = {}
		['title', 'description', 'image'].each { |att|
			seo[att] = seo_obj.send(att.to_sym) if seo_obj.respond_to?(att.to_sym)
			seo.delete(att) if seo[att].blank?
		}
		case seo.size
		when 0
			return nil
		else
			return seo
		end
	end

	#
	# Get a slug for a record based on fields returned by Dato, preferring slug fields
	#
	# @param [Object] record A record object from the Dato API
	#
	# @return [String] A slug that can be used for this record
	#
	def self.slug(record, unique = false, use_title = nil)
		@record_count ||= 0
		@record_count += 1
		if unique
			@slugstore ||= {}
			@slugstore[unique] ||= []
			@slugs = @slugstore[unique]
		end
		
		url = ''
		title = ''
		id = ''

		if record.respond_to?(:url)
			url = record.url.to_s
		elsif record.respond_to?(:slug)
			url = record.slug.to_s
		end

		if use_title
			title = use_title
		else
			title = record.name.to_s if record.respond_to?(:name)
			title = record.title.to_s if record.respond_to?(:title)
		end

		id = record.id.to_s if record.respond_to?(:id)

		if url.present?
			if unique
				url << '-' + @slugs.count(url).to_s if @slugs.include?(url)
				@slugs << url
			end
			return url
		end

		title = title.downcase.gsub(/[^\w\s\-]+/, '').gsub(/[\s\-]+/, '-').gsub(/^-+|-+$/, '')
		title = title.sub('fieldstone', '').split('-').reject { |f|
			f.length <= 2 ||
			[
			# articles
				#'a', 'an',
				'the',
			# conjunctions
				'for', 'and', 'nor', 'but',
				#'or',
				'yet',
				#'so',
			# prepositions (common)
				#'of',
				#'in',
				#'to',
				'with',
				#'on',
				#'at',
				'from',
				#'by',
				#'as',
				'into',
				'like',
				'over',
				'out'
			].include?(f)
		}.take(6).join('-')
		if title.present?
			title = I18n.transliterate(title)
			if unique
				title << '-' + @slugs.count(title).to_s if @slugs.include?(title)
				@slugs << title
			end
			return title
		end

		return id if id.present? # Guaranteed unique
		return 'page-' + @record_count.to_s.rjust(4, '0') # Guaranteed unique
	end

	def self.tree_recurse(model, &block)
		roots = model.select { |record| !record.parent }
		tree_branch(roots, 0, 1, nil, &block)
	end

	def self.tree_branch(records, index = 0, level = 1, parent = nil, &block)
		records.sort_by!(&:position)
		records.each do |record|
			index = index + 1

			# This record
			block.call(record, index, level, parent)

			# Children
			if record.children
				tree_branch(record.children, index, level + 1, record, &block)
				index = index + record.children.size
			end

		end
	end

	def self.drop_blocks(modular_field, include = true)
		blocks = []
		if defined?(Blocks)
			modular_field.each_with_index do |block, index|
				type = block.item_type.api_key
				if Blocks.respond_to?(type)
					blocks << Blocks.public_send(type, block, index, include)
				else
					blocks << "<!-- No handler defined for block of type '#{type}' -->"
				end
			end
		end
		return blocks.join("\n\n")
	end

end