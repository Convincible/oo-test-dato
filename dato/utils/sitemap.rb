module Sitemap

    def self.locales(id)
        $sitemap.dial[id].call([]).keys.map { |k| k.to_s }
    end

end