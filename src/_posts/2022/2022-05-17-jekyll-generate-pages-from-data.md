---
author: christian
title: 'Seiten mithilfe von Data Files in Jekyll erzeugen'
locale: de
tags: [ jekyll, ruby, html ]
---

Mit ein wenig Ruby Code kann man neben den üblichen
Blog Beiträgen auch andere Seiten in Jekyll dynamisch 
erzeugen lassen.

Jekyll bietet mit [Data Files][datafiles] einen Weg an, strukturierte Daten in Form
von YAML, JSON oder CSV Dateien abzulegen.

[datafiles]: https://jekyllrb.com/docs/datafiles/
[github]: https://github.com/perryflynn/serverless.industries

```yml
# src/_data/tags.yml
- glyph: <i class="mdi mdi-android"></i>
  name: android
- glyph: <i class="mdi mdi-ansible"></i>
  name: ansible
- glyph: <i class="mdi mdi-api"></i>
  name: api
```

Diese Datei wird hier in diesem Blog dazu verwendet, den Tags
passende Icons zuzuordnen.

Nun zum Jekyll Plugin welches die Seiten erzeugt. Jede Ruby Datei im Unterordner
`_plugins` wird automatisch als Plugin geladen.

Dank der sehr guten Trennung zwischen Daten und Templates muss in dem Ruby Code
gar nicht so viel gemacht werden. Der Code iteriert über alle definierten Tags,
fügt die Infos aus dem Data File und die Liste der verlinkten Beiträge (sortiert
nach Sprache) hinzu und erzeugt daraus eine neue Seite.

```rb
# src/_plugins/tagpage.rb
module TagPagePlugin
    class TagPageGenerator < Jekyll::Generator
        safe true
    
        def generate(site)
            site.tags.each do |tagname,items|
                # get taginfo from data file
                taginfo = site.data['tags'].select { |e| e['name']==tagname }.first
                # split post list by language code, defined in all posts in the frontmatter
                bylang = items.group_by { |p| p['locale'] }
                # create page object
                site.pages << TagPage.new(site, tagname, taginfo, bylang)
            end
        end
    end
  
    class TagPage < Jekyll::Page
        def initialize(site, tag, taginfo, posts)
            # properties
            @site = site
            @tag = tag
            @taginfo = taginfo
            @tagposts = posts
            @base = site.source
    
            # All pages have the same filename, so define attributes straight away.
            @basename = 'index'      # filename without the extension.
            @ext      = '.html'      # the extension.
            @name     = 'index.html' # basically @basename + @ext.
    
            # Initialize data hash the page frontmatter
            @data = {
                'title' => 'Articles tagged with '+@tag,
                'tagname' => @tag,
                'taginfo' => @taginfo,
                'tagposts' => @tagposts
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
```

Wichtig ist hier die **Zuweisung des Seitentyps** `tags`. Dieser wird in der `_config.yml`
dafür verwendet, den dynamisch generierten Tag-Seiten ein Template und eine URL zuzuweisen:

```yml
# src/_config.yml
defaults:
  - scope:
      path: ""
      type: tags
    values:
      layout: tagpage
      permalink: tag/:tagname:output_ext
```

Als letzter Schritt fehlt noch die entsprechende Layout Datei:

```html
---
---

<!-- src/_layouts/tagpage.html -->
{{'{{'}}page.taginfo.glyph|default: ''}}
{{'{{'}}page.tagname}}
```

Jekyll sollte nun Seiten alá `/tag/android.html` erzeugen, welche das Icon
und den Tagnamen anzeigen. Der Rest funktioniert exakt genau so wie bei den Posts.

Live kann man sich dieses Beispiel hier in diesem Blog in der Tag Liste anschauen.
Den passenden Code dazu gibt es [auf GitHub][github].
