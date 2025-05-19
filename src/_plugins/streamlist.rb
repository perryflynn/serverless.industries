module StreamListPagePlugin

    class StreamListPageGenerator < Jekyll::Generator
        safe true

        def generate(site)
            streamdata = site.data['stream']

            streamdata.each do |item|
                cparts = item['created_at'].split("-")
                item['itemyear'] = cparts[0]
                item['itemmonth'] = cparts[1]
                item['itemyearmonth'] = "#{cparts[0]}-#{cparts[1]}"
            end

            mymonth = streamdata.group_by { |item| item['itemyearmonth'] }

            mymonth.each do |key, items|
                site.pages << StreamListPage.new(site, key, items)
            end
        end
    end

    class StreamListPage < Jekyll::Page
        def initialize(site, month, items)
            # properties
            @site = site
            @base = site.source
            @month = month
            @items = items.sort_by { |item| item['created_at'] }.reverse

            # All pages have the same filename, so define attributes straight away.
            @basename = 'index'      # filename without the extension.
            @ext      = '.html'      # the extension.
            @name     = 'index.html' # basically @basename + @ext.

            # Initialize data hash the page frontmatter
            @data = {
                'title' => 'Stream items for '+@month,
                'streamitems' => @items,
                'locale' => 'en'
            }

            # Look up front matter defaults scoped to type `stream`, if given key
            # doesn't exist in the `data` hash.
            data.default_proc = proc do |_, key|
                site.frontmatter_defaults.find(relative_path, :streamlists, key)
            end
        end

        # Placeholders that are used in constructing page URL
        def url_placeholders
            {
                :basename   => basename,
                :year   => @items[0]['itemyear'],
                :month   => @items[0]['itemmonth'],
                :output_ext => output_ext
            }
        end
    end

end
