require 'date'

module StreamListPagePlugin

    class StreamListPageGenerator < Jekyll::Generator
        safe true

        def generate(site)
            streamdata = site.data['stream'] || []
            streamdata = streamdata.sort_by { |item| item['created_at'] }.reverse

            streamdata.each do |item|
                cparts = item['created_at'].split("-")
                item['itemyear'] = cparts[0]
                item['itemmonth'] = cparts[1]
                item['itemyearmonth'] = "#{cparts[0]}-#{cparts[1]}"
                item['itemcreation'] = DateTime.strptime("#{item['created_at']}", "%Y-%m-%d %H:%M:%S")

                site.pages << StreamListPage.new(site, 'singleview', nil, [ item ], item)
            end

            monthlist = []
            mymonth = streamdata.group_by { |item| item['itemyearmonth'] }

            mymonth.each do |key, items|
                site.pages << StreamListPage.new(site, 'monthview', key, items, nil)
                monthlist.push([ items[0]['itemyear'], items[0]['itemmonth'] ])
            end

            site.data['stream'] = streamdata

            maxage = DateTime.now - (6 * 30)
            site.data['streamrecent'] = streamdata.select { |item| item['itemcreation'] >= maxage }
            site.data['streammonths'] = monthlist
        end
    end

    class StreamListPage < Jekyll::Page
        def initialize(site, mode, month, items, item)
            # properties
            @site = site
            @base = site.source
            @month = month
            @items = items.sort_by { |item| item['created_at'] }.reverse || [ item ]
            @item = item || @items[0]

            # All pages have the same filename, so define attributes straight away.
            @basename = 'index'      # filename without the extension.
            @ext      = '.html'      # the extension.
            @name     = 'index.html' # basically @basename + @ext.

            # Initialize data hash the page frontmatter
            type = :streamlists
            if mode == 'monthview'
                @data = {
                    'title' => 'Stream items for '+@month,
                    'streamitems' => @items,
                    'streamitem' => @item,
                    'locale' => 'en'
                }
            else
                @data = {
                    'title' => 'Stream item '+@item['id'],
                    'streamitems' => @items,
                    'streamitem' => @item,
                    'locale' => 'en'
                }
                type = :streams
            end

            # Look up front matter defaults scoped to type `stream`, if given key
            # doesn't exist in the `data` hash.
            data.default_proc = proc do |_, key|
                site.frontmatter_defaults.find(relative_path, type, key)
            end
        end

        # Placeholders that are used in constructing page URL
        def url_placeholders
            {
                :basename   => basename,
                :year   => @items[0]['itemyear'],
                :month   => @items[0]['itemmonth'],
                :streamitemid => @items[0]['id'],
                :output_ext => output_ext
            }
        end
    end

end
