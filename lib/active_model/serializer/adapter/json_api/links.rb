module ActiveModel
  class Serializer
    class Adapter
      class JsonApi < Adapter
        module Links
          extend ActiveSupport::Concern

          included do |base|
            base.instance_eval do
              attr_accessor :links
            end
          end
                   
          class_methods do
            def inherited(subclass)
              subclass._links = self._links.try(:dup) || {}
            end
          
            def link(name, opts = {}, &block)
              href = opts[:as] || block
              return unless href && [:self,:related].include?(name)
              target = opts[:for] || :self
              links[target] = { name => href }      
            end
          end

          def links
            resource_links = self.class._links[:self]
            return unless resource_links
            evaluated_links = {}
            resource_links.each do |name, href_or_block|
              link = href_or_block.respond_to?(:call) ? href_or_block.call(serializer) : href_or_block
              evaluated_links[name] = link
              yield name, link
            end
            evaluated_links
          end
        end
      end
    end
  end
end
