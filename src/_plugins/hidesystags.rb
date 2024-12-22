module Jekyll
    module HideSysTagsFilter

        def hide_systags(tags)
            tags.reject { |t| t.start_with?('projects:') }
        end

    end
end

Liquid::Template.register_filter(Jekyll::HideSysTagsFilter)
