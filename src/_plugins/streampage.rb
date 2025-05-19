module StreamPagePlugin

    class StreamPageGenerator < Jekyll::Generator
        safe true

        def generate(site)
            site.data['stream'].each do |item|

                # create page object
                site.pages << StreamPage.new(site, item)

            end
        end
    end

    class StreamPage < Jekyll::Page
        def initialize(site, item)
            # properties
            @site = site
            @iteminfo = item
            @base = site.source

            # All pages have the same filename, so define attributes straight away.
            @basename = 'index'      # filename without the extension.
            @ext      = '.html'      # the extension.
            @name     = 'index.html' # basically @basename + @ext.

            @year = @iteminfo['created_at'].split("-")[0]
            @month = @iteminfo['created_at'].split("-")[1]

            # Initialize data hash the page frontmatter
            @data = {
                'title' => 'Stream item '+@iteminfo['id'],
                'streamitem' => @iteminfo,
                'streamitemid' => @iteminfo['id'],
                'locale' => 'en',
                'robot_noindex' => true
            }

            # Look up front matter defaults scoped to type `stream`, if given key
            # doesn't exist in the `data` hash.
            data.default_proc = proc do |_, key|
                site.frontmatter_defaults.find(relative_path, :streams, key)
            end
        end

        # Placeholders that are used in constructing page URL
        def url_placeholders
            {
                :streamitemid => @iteminfo['id'],
                :basename   => basename,
                :year   => @year,
                :month   => @month,
                :output_ext => output_ext
            }
        end
    end

end
