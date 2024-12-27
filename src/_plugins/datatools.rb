module Jekyll
    module DataToolsFilter

        def tokeyvalues(tags)
            result = []
            tags.each do |keyname, value|
                result.append([ keyname, value ])
            end

            result
        end

    end
end

Liquid::Template.register_filter(Jekyll::DataToolsFilter)
