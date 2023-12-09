module FrontPagePlugin
    class FrontPageGenerator < Jekyll::Generator

        safe true

        def generate(site)

            # group by ref or id
            byref = site.posts.docs.group_by { |p| p.data['ref'] || p.id }

            byref.each do |key, posts|

                # ensure frontmatter fields
                posts.each do |post|
                    unless post.data['locale']
                        post.data['locale'] = 'de'
                    end
                    unless post.data.key?('visible')
                        post.data['visible'] = true
                    end
                end

                # get list of locales
                locales = posts.map { |post| post.data['locale'] }

                # sort locale in reverse order, so that en wins against de
                posts.sort_by { |post| post.data['locale'] }.reverse.each_with_index do |post, postindex|
                    if postindex <= 0 && post.data['visible']
                        # add frontpage category to first post in one ref group
                        post.data['categories'].push('frontpage')
                    end

                    post.data['available_locales'] = locales
                    post.data['categories'].push("language-#{post.data['locale']}")
                end

            end

        end

    end
end
