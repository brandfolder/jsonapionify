module JSONAPIonify::Api
  module Resource::Definitions::Pagination
    class PaginationLinksDelegate

      def initialize(url, params, links)
        @url    = url
        @params = params
        @links  = links
      end

      %i{first last next prev}.each do |method|
        define_method method do |**options|
          @links[method] = URI.parse(@url).tap do |uri|
            page_params = { page: options }.deep_stringify_keys
            uri.query   = @params.merge(page_params).to_param
          end.to_s
        end
      end

    end

    def self.extended(klass)
      klass.class_eval do
        include InstanceMethods

        inherited_hash_attribute :pagination_strategies

        define_pagination_strategy 'Object' do |collection|
          collection
        end

        define_pagination_strategy 'Enumerable' do |collection, params, links, per, context|
          size = Integer(params['first'] || params['last'] || per)

          slice =
            if (params['before'] && params['first']) || (params['after'] && params['last'])
              error :forbidden do
                detail 'Illegal combination of parameters'
              end
            elsif (after = params['after'])
              key_values = parse_and_validate_cursor(:after, after, context)
              array_select_past_cursor(collection, context.sort_params, key_values).first(size)
            elsif (before = params['before'])
              key_values = parse_and_validate_cursor(:before, before, context)
              array_select_past_cursor(collection, context.sort_params.invert, key_values).last(size)
            elsif params['last']
              collection.last(size)
            else
              collection.first(size)
            end

          context.meta[:total_count] = collection.count

          links.first first: size
          links.last last: size
          links.prev before: build_cursor(context: context, instance: slice.first), last: size unless !slice.first || slice.first == collection.first
          links.next after: build_cursor(context: context, instance: slice.last), first: size unless !slice.last || slice.last == collection.last

          slice
        end

        define_pagination_strategy 'ActiveRecord::Relation' do |collection, params, links, per, context|
          size = Integer(params['first'] || params['last'] || per)

          slice =
            if (params['before'] && params['first']) || (params['after'] && params['last'])
              error :forbidden do
                detail 'Illegal combination of parameters'
              end
            elsif (after = params['after'])
              key_values = parse_and_validate_cursor(:after, after, context)
              arel_select_past_cursor(collection, context.sort_params, key_values).limit(size)
            elsif (before = params['before'])
              key_values = parse_and_validate_cursor(:before, before, context)
              ids        = arel_select_past_cursor(collection, context.sort_params.invert, key_values)
                             .reverse_order.limit(size).pluck(id_attribute)
              collection.where(id_attribute => ids)
            elsif params['last']
              ids = collection.reverse_order.limit(size).pluck(id_attribute)
              collection.where(id_attribute => ids).limit(size)
            else
              collection.limit(size)
            end

          context.meta[:total_count] = collection.count

          links.first first: size
          links.last last: size
          links.prev before: build_cursor(context: context, instance: slice.first), last: size unless !slice.first || slice.first == collection.first
          links.next after: build_cursor(context: context, instance: slice.last), first: size unless !slice.last || slice.last == collection.last

          slice
        end
      end
    end

    def define_pagination_strategy(mod, &block)
      pagination_strategies[mod.to_s] = block
    end

    def enable_pagination(per: 50)
      param :page, :after, actions: %i{list}
      param :page, :before, actions: %i{list}
      param :page, :first, actions: %i{list}
      param :page, :last, actions: %i{list}
      context :paginated_collection, readonly: true do |context, nested_request: false, sorted_collection:, collection:, request:, params:, links:|
        if !nested_request
          collection = sorted_collection
          _, block   = pagination_strategies.to_a.reverse.to_h.find do |mod, _|
            Object.const_defined?(mod, false) && collection.class <= Object.const_get(mod, false)
          end

          links_delegate = PaginationLinksDelegate.new(request.url, params, links)

          instance_exec(
            collection,
            request.params['page'] || {},
            links_delegate,
            per,
            context,
            &block
          )
        else
          collection
        end
      end
    end

    module InstanceMethods

      def array_select_past_cursor(collection, sort_params, key_values)
        sort_params.length.times.map do |i|
          set                             = sort_params[0..i]
          *contains_fields, outside_field = set

          # Collect the contains results
          contains_results                = contains_fields.map do |field|
            collection.select do |item|
              value          = item.send(field.name)
              expected_value = key_values[field.name]
              value && value.send(field.contains_operator, expected_value)
            end
          end

          # Collect the outside results
          outside_results                 = collection.select do |item|
            value          = item.send(outside_field.name)
            expected_value = key_values[outside_field.name.to_s]
            value && value.send(outside_field.outside_operator, expected_value)
          end

          # Finish the query
          [*contains_results, outside_results].reduce(:&)
        end.reduce(:|) || []
      end

      def arel_select_past_cursor(collection, sort_params, key_values)
        subquery = sort_params.length.times.map do |i|
          set                             = sort_params[0..i]
          *contains_fields, outside_field = set
          contains_fields.reduce(collection.reorder(nil)) do |relation, field|
            relation.where(
              collection.arel_table[field.name].send(field.contains_arel, key_values[field.name.to_s])
            )
          end.where(
            collection.arel_table[outside_field.name].send(outside_field.outside_arel, key_values[outside_field.name.to_s])
          )
        end.map { |rel| "( #{rel.to_sql} )" }.join(' UNION ')
        collection.from("(#{subquery}) AS #{collection.table_name}").tap(&:first)
      rescue ActiveRecord::StatementInvalid
        collection.where(id: collection.find_by_sql(subquery).map(&:id))
      end

      def parse_and_validate_cursor(param, cursor, context)
        should_error = false
        options      = JSON.parse(Base64.urlsafe_decode64(cursor))

        # Validate Type
        unless options['t'] == self.class.type
          should_error = true
          error(:page_parameter_invalid, :page, param) do
            detail 'The cursor type does not match the resource'
          end
        end

        # Validate Sort
        unless options['s'] == context.params['sort']
          should_error = true
          error(:page_parameter_invalid, :page, param) do
            detail 'The cursor sort does not match the request sort'
          end
        end
        halt if should_error

        options['a']
      end
    end

  end
end
