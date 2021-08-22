module Markdown

	def self.blockquote(quote, by = '')
		quote = quote.to_s.split("\n")
		quote += ['', "&mdash; <cite>#{by.to_s.strip}</cite>"] unless by.blank?
		return quote.map{ |line| '> ' + line }.join("\n")
	end

	def self.link(text, href, title = '', kramdown = '')
		return "[#{text.to_s}](#{href.to_s}" + (title.blank? ? '' : ' "' + title.to_s + '"') + ')' + kramdown unless href.blank?
		return text.to_s
	end

	def self.image(image_hash)
		image_hash.stringify_keys!
		if image_hash && image_hash['url'].present?
			alt = demand(image_hash['alt'], '')
			src = image_hash['url']
			if image_hash['title'].present?
				title = ' "' + image_hash['title'] + '"'
			else
				title = ''
			end
			return "![#{alt}](#{src}#{title})"
		else
			return ''
		end
	end

	def self.h(text, level = 1)
		return ('#' * level) + ' ' + text
	end

end