require 'set'

module JSONAPIonify::Api
  module Resource::Definitions::Sorting
    using JSONAPIonify::DeepSortCollection
    using JSONAPIonify::DestructuredProc

    def self.extended(klass)
      klass.class_eval do
        inherited_hash_attribute :sorting_strategies
        delegate :sort_fields_from_sort_string, to: :class

        # Define Contexts
        context :sorted_collection, readonly: true do |context, collection:, sort_params:, nested_request: false|
          if !nested_request
            _, block = sorting_strategies.to_a.reverse.to_h.find do |mod, _|
              Object.const_defined?(mod, false) && collection.class <= Object.const_get(mod, false)
            end
            context.reset(:sort_params)
            instance_exec(collection, sort_params, context, &block.destructure)
          else
            collection
          end
        end

        context(:sort_params, readonly: true, persisted: true) do |params:|
          sort_fields_from_sort_string(params['sort'])
        end

        define_sorting_strategy('Object') do |collection|
          collection
        end

        define_sorting_strategy('Enumerable') do |collection, fields|
          collection.to_a.deep_sort(fields.to_h)
        end

        define_sorting_strategy('ActiveRecord::Relation') do |collection, fields|
          collection.reorder(fields.to_h).order(self.class.id_attribute)
        end

      end
    end

    def define_sorting_strategy(mod, &block)
      sorting_strategies[mod.to_s] = block
    end

    def default_sort(options)
      string =
        case options
        when Hash, Array
          options.map do |k, v|
            v.to_s.downcase == 'asc' ? "-#{k}" : k.to_s
          end.join(',')
        else
          options.to_s
        end
      param :sort, default: string
    end

    def sort_attrs_from_sort(sort_string)
      sort_attrs = sort_string.split(',').map do |a|
        a == 'id' ? id_attribute.to_s : a.to_s
      end
      sort_attrs.uniq
    end

    def sort_fields_from_sort_string(sort_string)
      field_specs = sort_string.to_s.split(',')
      field_specs.each_with_object(SortFieldSet.new) do |field_spec, array|
        field_name, resource = field_spec.split('.').map(&:to_sym).reverse

        # Skip unless this resource
        next unless self <= self.api.resource(resource || type)

        # Assign Sort Fields
        field = SortField.new(field_name)
        field = SortField.new(id_attribute.to_s) if field.id?
        array << field
      end.tap do |field_set|
        field_set << SortField.new(id_attribute.to_s)
      end
    end

  end
end
