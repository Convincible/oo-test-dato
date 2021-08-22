module Jekyll

	SOURCE_FOLDER = 'source' # No leading slash
	DATA_FOLDER = File.join(SOURCE_FOLDER, '_data')
	COLLECTIONS_FOLDER = File.join(SOURCE_FOLDER, 'content')
	
	# DatoAPI api_keys for models, mapped to URL paths
	URLS = {
		home: {
			en: '',
			fr: ''
		},
		activity: {
			en: 'activity',
			fr: 'activite'
		}
	}

	# Dato models, mapped to Jekyll collection folders
	# If a model isn't defined here, assumes path "_model"
	COLLECTIONS = {
		home: '_pages'
	}

	#
	# Create a Markdown page with frontmatter and content
	#
	# @param [Hash] frontmatter Hash of keys/values to become YAML
	# @param [Array, String] content Array of lines of markdown, or String of markdown
	#
	# @return [String] String of valid whole page
	#
	def self.page(frontmatter, content)
		content = [content] unless content.is_a?(Array)
		[
			frontmatter.deep_stringify_keys.to_yaml.strip,
			"---\n",
			content.flatten.reject(&:blank?).join("\n\n")
		].reject(&:blank?).join("\n")
	end

	#
	# Return the URL to a page based on the kind of model
	#
	# @param [String] model The model to use
	# @param [String] page The page to get a link to
	# @param [String] fragment If any
	#
	# @return [String] Relative URL to the page
	#
	def self.url(model, page = nil, fragment = nil)
		url_root = URLS.dial(model.to_sym, I18n.locale).call(model.to_s)
		return File.join(*['', url_root, page].reject(&:nil?)) + (fragment ? '#section-' + fragment.to_s : '')
	end

	def self.path(*filepath)
		filepath = filepath.flatten.reject(&:nil?).map { |p| p.to_s.strip }
		File.join(Jekyll::COLLECTIONS_FOLDER, *filepath)
	end

	def self.slamdown(html, starting_level = 2)
		html = html.to_s.strip

		# Find the lowest-numbered heading in the whole doc (nil if no headings)
		highest_h = html.scan(/<h(\d)/).flatten.uniq.sort.map(&:to_i).min
		offset = 0
		if highest_h
			offset = starting_level - highest_h
		end

		if html.length > 0
			kramdoc = Kramdown::Document.new(html, {
				html_to_native: true,
				line_width: -1,
				remove_block_html_tags: true,
				remove_span_html_tags: true,
				header_offset: offset,
				entity_output: "symbolic",
				hard_wrap: false,
				smart_quotes: "lsquo,rsquo,ldquo,rdquo"
			})

			# Convert HTML to kramdown
			markdown = kramdoc.to_kramdown.rstrip

			# Tidy up the resulting Markdown:
			# * Split all lines
			# * Remove trailing space
			# * Ignore empty lines
			# * Put back together with two newlines between each Markdown line
			#markdown = markdown.gsub("\r",'').split("\n").map { |line|
			#	line.rstrip
			#}.join("\n")

			return markdown
		else
			return ''
		end
	end

	def self.slamup(markdown)
		html = Kramdown::Document.new(markdown, {
			html_to_native: true,
			line_width: -1,
			remove_block_html_tags: true,
			remove_span_html_tags: true,
			entity_output: "symbolic",
			hard_wrap: false,
			smart_quotes: "lsquo,rsquo,ldquo,rdquo"
		}).to_html
	end

	def self.sanitize(html, *allowed)
		# Map allowed els
		allowed.map! do |el|
			case el
			when :emphasis
				['strong', 'em']
			when Array
				el.flatten.map(&:to_s)
			else
				el.to_s
			end
		end
		allowed = allowed.flatten.uniq
		
		# Add allowed attributes for els
		attributes = {}
		#protocols = {}
		allowed.each do |el|
			case el
			when 'a'
				attributes[el] = ['href']
				#protocols[el] = {'href' => ['http', 'https', 'mailto']}
			end
		end

		t = ->(node) {
			case node[:node_name]
			when 'b'
				node[:node].name = 'strong'
			when 'i'
				node[:node].name = 'em'
			end
		}

		clean = Sanitize.fragment(
			html,
			:elements => allowed,
			:attributes => attributes,
			#:protocols => protocols,
			:transformers => t
		) # Removes all but allowed elements
		return clean.strip
	end

	def self.inlinify(string, sep = ' ')
		return string.gsub(/\s*[\n\r]+\s*/, sep).squish
	end

	def self.singleline(html, *allowed)
		clean = sanitize(html, *allowed)
		inline = inlinify(clean)
		markdown = slamdown(inline)
		return markdown
	end

	#
	# Converts markdown to HTML, then removes all the tags, inlinifies, and truncates.
	#
	def self.excerpt(markdown)
		html = slamup(markdown)
		clean = sanitize(html)
		inline = inlinify(clean)
		truncated = inline.split[0...50].join(' ') # No excerpt can be longer than 50 words
		truncated << '...' if truncated.length < inline.length
		return truncated
	end
end