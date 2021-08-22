source "https://rubygems.org"

gem "jekyll", "~> 4.2"
gem "dato", "~> 0.8"

gem "sanitize"

# Low-level supporting gems
gem "demand", "~> 1.1.1"
gem "key_dial", "~> 1.2.0"
gem "activesupport", "~> 6.1"
gem "stringex", "~> 2.8"

# More complex gems
gem "kramdown", "~>2.3" # Will be used by Jekyll anyway, but needed earlier in Dato processing

group :jekyll_plugins do
	# Plugins for this site stored locally
	#gem "jekyll-tag_io", :path => "source/_gems/tag_io"
	#gem "jekyll-asset_manager", :path => "source/_gems/asset_manager"
	#gem "jekyll-img", :path => "source/_gems/img"
	
	#gem "jekyll-paginate-v2", git: 'https://github.com/ConvincibleMedia/jekyll-paginate-v2', branch: 'dev'
end

group :development do
	gem "pry"
	gem "pry-byebug"
	gem "jekyll-debug"
	gem "awesome_print"
end