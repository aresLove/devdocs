module Docs
  class React
    class EntriesFilter < Docs::EntriesFilter
      API_SLUGS = %w(
        docs/top-level-api
        docs/component-api
        docs/component-specs
      )

      REPLACE_TYPES = {
        'Quick Start' => 'Guides',
        'User Guide' => 'Guides',
        'The Basics' => 'Getting Started',
        'apis' => 'APIs',
        'components' => 'Components'
      }

      def get_name
        at_css('h1').children.select(&:text?).map(&:content).join.strip
      end

      def get_type
        link = at_css('.nav-docs-section .active, .toc .active')
        return 'Miscellaneous' unless link
        section = link.ancestors('.nav-docs-section, section').first
        type = section.at_css('h3').content.strip
        type = REPLACE_TYPES[type] || type
        type += ": #{name}" if type == 'Components'
        type
      end

      def additional_entries
        if API_SLUGS.include?(slug)
          css('.inner-content h3, .inner-content h4').map do |node|
            name = node.content
            name.remove! %r{[#\(\)]}
            name.remove! %r{\w+\:}
            id = node.at_css('.anchor')['name']
            type = slug.include?('component') ? 'Component' : 'React'
            [name, id, type]
          end
        else
          entries = []

          css('.props > .prop > .propTitle', '.props > .prop > .methodTitle').each do |node| # react-native
            name = node.children.find(&:text?).try(:content)
            next if name.blank?
            sep = node.content.include?('static') ? '.' : '#'
            name.prepend(self.name + sep)
            name << '()' if node['class'].include?('methodTitle')
            id = node.at_css('.anchor')['name']
            entries << [name, id]
          end

          css('.apiIndex a pre').each do |node| # relay
            next unless node.parent['href'].start_with?('#')
            id = node.parent['href'].remove('#')
            name = node.content.strip
            sep = name.start_with?('static') ? '.' : '#'
            name.remove! %r{(abstract|static) }
            name.sub! %r{\(.*\)}, '()'
            name.prepend(self.name + sep)
            entries << [name, id]
          end

          entries
        end
      end
    end
  end
end
