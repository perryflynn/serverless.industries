module FrontPagePlugin
    class FrontPageGenerator < Jekyll::Generator

        safe true

        def generate(site)

            # group by ref or id
            byref = site.posts.docs.group_by { |p| p.data['ref'] || p.id }

            byref.each do |key, posts|
                # sort locale in reverse order, so that en wins against de
                posts.sort_by { |post| post.data['locale'] }.reverse.each_with_index do |post, postindex|
                    if postindex <= 0
                        # add frontpage category to first post in one ref group
                        post.data['categories'].push('frontpage')
                    end
                end
            end

        end

    end
end
