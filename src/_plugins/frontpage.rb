module FrontPagePlugin

    class FrontPageGenerator < Jekyll::Generator
        safe true

        def generate(site)

            byref = site.posts.docs.group_by { |p| p.data['ref'] || p.id }

            byref.each do |key, posts|
                posts.sort_by { |post| post.data['locale'] }.reverse.each_with_index do |post, postindex|
                    if postindex <= 0
                        post.data['categories'].push('frontpage')
                    end
                end
            end

        end
    end

end
