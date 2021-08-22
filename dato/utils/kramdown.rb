#
# Extend how Kramdown converts HTML to Markdown, forcing simpler output
#
require 'kramdown' # For slamming down CMS output

module ::Kramdown
	module Converter
		class Kramdown < Base
			# Access original methods
			alias super_convert convert
			alias super_convert_a convert_a
			alias super_convert_html_element convert_html_element
			#alias super_convert_img convert_img
			#alias super_convert_header convert_header
			alias super_convert_p convert_p
			#alias super_convert_li convert_li
			#alias super_convert_ul convert_ul
			alias super_inner inner
			alias super_convert_text convert_text
			#alias super_convert_table convert_table
			
			# Override general convert method for debug and nested list fix
			def convert(el, opts = {indent: 0})
				res = super_convert(el, opts)
				res.sub!(/[\r\n]+$/, "\n") if [:ul, :dl, :ol].include?(el.type) && @stack.last.type == :li
				#res = "<#{el.type} #{el.options.merge({block: el.block?, parent: @stack.last.type}).map{|o| o[0].to_s + '="' + o[1].to_s + '"'}.join(' ')}>" + res + "</#{el.type}>"
				res
			end

			def inner(el, opts = {indent: 0})
				res = super_inner(el, opts)
				if el.type == :html_element && el.options[:category] != :span
					# For html elements, put each element on a newline
					res = res.gsub(/^[\s\r\n]+|[\s\r\n]+$/, "\n")
				end
				res
			end
			
			def ial_for_element(el)
				res = []
				if el.type == :p && el.attr['class'] && [].include?(el.attr['class'])
					res << '.' + el.attr['class'].strip
				end
				res = res.join(' ')

				res.strip.empty? ? nil : "{: #{res}}"
			end

			# Override how HTML elements will be processed

			#def convert_text(el, opts)
			#	output = super_convert_text(el, opts)
			#	# Do something extra to all text
			#	output
			#end

			# Capture paragraphs trying to be rules (<p>---</p>)
			def convert_p(el, opts)
				res = super_convert_p(el, opts)
				if /^(\*{3,}|\-{3,}|_{3,})$/.match?(res)
					res = convert_hr(nil, nil)
				end
				res
			end

			# Override to avoid indexing, necessary for block parsing
			def convert_a(el, opts)
				link = super_convert_a(el, opts)
				if link.match(/\[([^\]]+)\]\[([^\]]+)\]/)
					index = $~[2].to_i - 1
					href = @linkrefs[index].attr['href']
					link = link.sub(/\[([^\]]+)\]\[([^\]]+)\]/, '[\1](' + href + ')')
					@linkrefs.delete_at(index)
				end
				link
			end

			def convert_entity(el, _opts)
				e = entity_to_str(el.value, el.options[:original])
				case e
				when "&nbsp;"
					' '
				else
					e
				end
			end

			def convert_html_element(el, opts)
				case el.value
				when 'table', 'tbody', 'thead', 'tfoot', 'tr', 'th', 'td'
					# Compress newlines within
					super_convert_html_element(el, opts).gsub(/[\n\r]+/, "\n")
				when 'figure', 'figcaption', 'cite', 'br', 'caption'
					super_convert_html_element(el, opts)
				when 'div', 'span'
					if @stack.last.type == :html_element
						super_convert_html_element(el, opts)
					else
						inner(el, opts)
					end
				else
					output = inner(el, opts)
					#output << "\n" if @stack.last.type != :html_element || @stack.last.options[:content_model] != :raw
					output
				end
			end

			# Override br so that:
			# - In headers, it gets hard-coded in
			# - Elsewhere, it reduces to a space
			def convert_br(el, opts)
				if [:header].include?(@stack.last.type)
					'<br />'
				else
					' '
				end
			end

			def convert_em(el, opts)
				convert_emphasis(el, opts, 1)
			end

			def convert_strong(el, opts)
				convert_emphasis(el, opts, 2)
			end

			def convert_emphasis(el, opts, strength = 1)
				inside = inner(el, opts)

				# Does the inside begin or end with white space?
				pad_front = inside.match(/^\s+/) ? $& : ''
				pad_back = inside.match(/\s+$/) ? $& : ''

				# Remove and save it
				inside.lstrip! if pad_front
				inside.rstrip! if pad_back

				if inside.length > 0
					# Only actually create this tag if there is content to emphasise
					pad_front + ('*' * strength) + inside + ('*' * strength) + pad_back
				else
					# Otherwise just keep the whitespace
					pad_front + pad_back
				end
			end

		end
	end
end