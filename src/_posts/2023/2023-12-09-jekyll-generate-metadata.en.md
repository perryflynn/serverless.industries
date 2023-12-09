---
author: christian
title: Generate tags and categories dynamically in Jekyll
locale: en
tags: [ jekyll, ruby ]
---

When a Jekyll Page is getting more complex, it's helpful to add custom meta data to pages and
posts. For example, add a auto generated category to only show the primary language version of 
a multi language post on the index page but also let single posts in a secondary language show up.

Frontmatter of the German post:

```yml
title: Static Binaries
locale: de
ref: static-binaries
```

Frontmatter of the English post:

```yml
title: Static Binaries
locale: en
ref: static-binaries
```

The `ref` Frontmatter field connects identical posts in different languages with each other.

The plugin is placed into the `_plugins/` directory. The `generate()` function
iterates though all existing pages and posts and modifies the Frontmatter data.

```rb
# _plugins/fontpage.rb
module FrontPagePlugin
    class FrontPageGenerator < Jekyll::Generator

        safe true

        def generate(site)

            # group by ref (or id if no ref defined)
            byref = site.posts.docs.group_by { |p| p.data['ref'] || p.id }

            byref.each do |key, posts|

                # ensure frontmatter fields
                posts.each do |post|
                    unless post.data['locale']
                        post.data['locale'] = 'de'
                    end
                end

                # get list of locales
                locales = posts.map { |post| post.data['locale'] }

                # sort posts by locale in reverse order, so that 'en' wins against 'de'
                posts.sort_by { |post| post.data['locale'] }.reverse.each_with_index do |post, postindex|
                    if postindex <= 0
                        # add frontpage category to first post in every ref group
                        post.data['categories'].push('frontpage')
                    end

                    # add locales list and language category to all posts
                    post.data['available_locales'] = locales
                    post.data['categories'].push("language-#{post.data['locale']}")
                end

            end

        end

    end
end
```

In [Jekyll Paginate v2](https://github.com/sverrirs/jekyll-paginate-v2) we can now filter the
index page by the auto generated categories. Also creating a main index with all postings
and an index for each language.

```yml
layout: localizedindex
title: Latest Posts
permalink: /index
pagination:
  enabled: true
  category: frontpage
```
