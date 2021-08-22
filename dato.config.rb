puts "\n"

# Low level supporting gems
require 'demand'
require 'key_dial'
require 'sanitize'

# Debug
$debug = ENV["NODE_ENV"] == "development"
if $debug
	puts "DEVELOPMENT ENVIRONMENT"
	require 'pry'
	require 'awesome_print'
	AwesomePrint.defaults = {
		raw: true
	}
end

# Hold onto the dato object
$dato = dato

def load(glob)
	Dir[glob].each { |file|
		result = require file
		puts "#{file} load " + (result ? 'success!' : 'failure.')
	}
end

# Load up utilities
load("./dato/utils/*.rb")
load("./dato/*.rb")

# Parse models
DatoAPI::get_models

# I18n
I18n.load_path << './source/_data/i18n.yml'
I18n.available_locales = [:en] # Override
DEFAULT_LOCALE = I18n.available_locales[0]

$sitemap = {}

DEFAULT_COLLECTION = 'pages'

DatoAPI.model.each do |model_name, model|
	
	puts 'Building sitemap for model: ' + model_name.to_s
	# Find the Handler class for this model
	handler = model_name.to_s.camelize
	if DatoAPI.const_defined?(handler)
		handler = DatoAPI::const_get(handler).new
	else
		handler = DatoAPI::Handler.new
		warn 'No handler defined for ' + model_name.to_s + '; using default.'
	end

	I18n.available_locales.each do |locale|
		I18n.with_locale(locale) do
				
			# Itemize single/plural models and iterate
			[model].flatten.each do |item|

				# Should this record be considered to exist?
				if handler.has_data?(item)

					$sitemap.dial[item.id][locale] = {
						title: handler.title(item),
						path: handler.folder(item),
						slug: handler.slug(item),
						loc: handler.url(item) # Can be a string or false = should not appear in sitemap.xml
					}
					
				end

			end

		end
	end
end


# Resources

I18n.available_locales.each do |locale|
	I18n.with_locale(locale) do

		handler = DatoAPI::Resources.new

		$dato.resources.each_with_index do |record, index|
			
			if handler.has_data?(record)

				create_post(Jekyll.path(handler.file(record))) do
					frontmatter(:yaml,
						{
							title: handler.title(record),
							data: {
								photo: DatoAPI.image(record.photo),
								role: handler.field(record, :role)
							}.merge(
								record.linkedin.present? ?
								{
									links: [
										{
											id: 'linkedin',
											title: 'LinkedIn',
											url: record.linkedin
										}
									]
								} : {}
							),
							locale: locale.to_s,
							order: index,
							meta: {
								id: record.id,
								locales: Sitemap.locales(record.id)
							}
						}
					)
					content(
						Jekyll::slamdown(handler.field(record, :bio))
					)
				end

			end

		end

	end
end