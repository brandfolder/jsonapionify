module JSONAPIonify::Api
  class Relationship::Many < Relationship

    prepend_class do
      rel = self.rel
      remove_action :read
      class << self
        undef_method :read
      end

      define_singleton_method(:show) do |**options, &block|
        options[:prepend] = 'relationships'
        define_action(:show, 'GET', **options, &block).response status: 200 do |context|
          context.response_object[:data] = build_identifier_collection(context.collection)
          context.meta[:total_count]     = context.collection.count
          context.response_object.to_json
        end
      end

      if rel.associate

        define_singleton_method(:replace) do |**options, &block|
          options[:prepend] = 'relationships'
          define_action(:replace, 'PATCH', **options, &block).response status: 200 do |context|
            context.owner_context.reset(:instance)
            context.reset(:collection)
            context.response_object[:data] = build_identifier_collection(context.collection)
            context.meta[:total_count]     = context.collection.count
            context.response_object.to_json
          end
        end

        define_singleton_method(:update) do |**options, &block|
          options[:prepend] = 'relationships'
          define_action(:update, 'POST', **options, &block).response status: 200 do |context|
            context.owner_context.reset(:instance)
            context.reset(:collection)
            context.response_object[:data] = build_identifier_collection(context.collection)
            context.meta[:total_count]     = context.collection.count
            context.response_object.to_json
          end
        end

        define_singleton_method(:remove) do |**options, &block|
          options[:prepend] = 'relationships'
          define_action(:remove, 'DELETE', **options, &block).response status: 200 do |context|
            context.owner_context.reset(:instance)
            context.reset(:collection)
            context.response_object[:data] = build_identifier_collection(context.collection)
            context.meta[:total_count]     = context.collection.count
            context.response_object.to_json
          end
        end

      end

      context :scope do |context|
        context.owner_context.instance.send(rel.name)
      end

      show
      if rel.associate
        replace { error_now :forbidden }
      end
    end
  end
end
