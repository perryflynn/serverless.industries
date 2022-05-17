module TagPagePlugin

    class TagPageGenerator < Jekyll::Generator
        safe true
    
        def generate(site)
            site.tags.each do |tagname,items|
                
                # get taginfo from data file
                taginfo = site.data['tags'].select { |e| e['name']==tagname }.first
                
                # split post list by language code
                bylang = items.group_by { |p| p['locale'] }
                
                # create page object
                site.pages << TagPage.new(site, tagname, taginfo, bylang, items.length)
            
            end
        end
    end
  
    class TagPage < Jekyll::Page
        def initialize(site, tag, taginfo, posts, pagecount)
            # properties
            @site = site
            @tag = tag
            @taginfo = taginfo
            @tagposts = posts
            @base = site.source
            @pagecount = pagecount
    
            # All pages have the same filename, so define attributes straight away.
            @basename = 'index'      # filename without the extension.
            @ext      = '.html'      # the extension.
            @name     = 'index.html' # basically @basename + @ext.
    
            # Initialize data hash the page frontmatter
            @data = {
                'title' => 'Articles tagged with '+@tag,
                'tagname' => @tag,
                'taginfo' => @taginfo,
                'tagposts' => @tagposts,
                'tagpostcount' => @pagecount
            }

            # Look up front matter defaults scoped to type `tags`, if given key
            # doesn't exist in the `data` hash.
            data.default_proc = proc do |_, key|
                site.frontmatter_defaults.find(relative_path, :tags, key)
            end
        end

        # Placeholders that are used in constructing page URL
        def url_placeholders
            {
                :tagname   => Jekyll::Utils.slugify(@tag),
                :basename   => basename,
                :output_ext => output_ext
            }
        end
    end

end
