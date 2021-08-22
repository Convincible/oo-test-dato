module Liquid

	#
	# Create a Liquid tag
	#
	# @param [String] tag Which tag to create
	# @param [Array] args Array of arguments to tag. Array item can be a Hash for a key/val pair.
	# @param [Boolean] closing If true, return the closing tag only
	#
	# @return [String] Valid Liquid tag string
	#
	def self.tag(tag, args = [], closing = false)
		args = [args] unless args.is_a?(Array)
		args = args.map { |arg|
			if arg.is_a?(Hash)
				arg = arg.map { |pair|
					key = pair[0].to_s
					val = pair[1].to_s
					if key.present? && val.present?
						key + '=' + val
					end
				}.reject(&:blank?).join(' ')
			end
			arg.to_s
		}.reject(&:blank?).join(' ')
		if closing
			return "<!--{% end#{tag} %}-->"
		else
			tag += ' ' if args.length > 0
			return "<!--{% #{tag}#{args} %}-->"
		end
	end

	#
	# Wrap content between Liquid tags
	#
	# @param [String, Array] content String of content to wrap, or Array of lines of content
	# @param [String] tag Which tag to use
	# @param [Array] args Array of arguments to add to the tag.
	# @param [Boolean] inline If true, no extra newlines are added within the tag
	#
	# @return [String] Valid Liquid tags wrapped around content
	#
	def self.wrap(content, tag, args = [], inline = false)
		newline = inline ? '' : "\n"
		content = content.join(newline * 2) if content.is_a?(Array)
		content = content.strip
		return tag(tag, args) + newline + content + newline +  tag(tag, args, true)
	end

end