module FrontPagePlugin
    class FrontPageGenerator < Jekyll::Generator

        safe true

        def generate(site)

            # generate custom properties
            site.posts.docs.each_with_index do |post, postindex|
                post.data['year'] = post.data['date'].strftime('%Y')
                post.data['month'] = post.data['date'].strftime('%m')
                post.data['yearmonth'] = "#{post.data['date'].strftime('%Y')}-#{post.data['date'].strftime('%m')}"
            end

            # group by ref or id
            byref = site.posts.docs.group_by { |p| p.data['ref'] || p.id }

            byref.each do |key, posts|

                # detect multiple posts with the same language in one ref group
                locales = posts.map { |p| p.data['locale'] }
                duplocales = locales.find_all { |e| locales.count(e) > 1 }

                unless duplocales.nil? || duplocales.length <= 0
                    raise StandardError.new "The ref '#{key}' contains multiple posts with the same language"
                end

                # ensure frontmatter fields
                posts.each do |post|
                    unless post.data['locale']
                        post.data['locale'] = 'de'
                    end
                    unless post.data.key?('visible')
                        post.data['visible'] = true
                    end
                end

                # sort locale in reverse order, so that en wins against de
                posts.sort_by { |post| post.data['locale'] }.reverse.each_with_index do |post, postindex|
                    if postindex <= 0 && post.data['visible']
                        # add frontpage category to first post in one ref group
                        post.data['categories'].push('frontpage')
                    end

                    post.data['available_locales'] = locales

                    if post.data['visible']
                        post.data['categories'].push("language-#{post.data['locale']}")
                    end
                end

            end

            # guides
            site.posts.docs.each_with_index do |post, postindex|
                if post.data.key?('posttype') && post.data['posttype'] == 'guide'
                    if post.data['visible']
                        post.data['categories'].push('guides')
                    end
                    post.data['tags'].push('guides')
                end
            end

        end

    end
end
