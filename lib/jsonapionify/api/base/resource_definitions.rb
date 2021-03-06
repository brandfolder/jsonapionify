module JSONAPIonify::Api
  module Base::ResourceDefinitions
    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        inherited_hash_attribute :resource_definitions
      end
    end

    def resource(type)
      raise ArgumentError, 'type required' if type.nil?
      type       = type.to_sym
      const_name = type.to_s.camelcase + 'Resource'
      return const_get(const_name, false) if const_defined?(const_name, false)
      raise Errors::ResourceNotFound, "Resource not defined: #{type}" unless resource_defined?(type)
      klass = Class.new(resource_class, &resource_definitions[type]).set_type(type)
      param(:fields, type)
      const_set const_name, klass
    rescue NameError => e
      raise e unless e.instance_of?(NameError)
      raise Errors::ResourceNotFound, "Resource not defined: #{type}"
    end

    def resource_defined?(name)
      load_resources
      !!resource_definitions[name]
    end

    def resources
      load_resources
      resource_definitions.map do |name, _|
        resource(name)
      end
    end

    def define_resource(name, extend: nil, &block)
      resource_definitions[name.to_sym] =
        if extend
          sup = superclass
          cur = self
          proc do
            extend_def =
              if name.to_sym == extend.to_sym && sup.respond_to?(:resource)
                sup.resource(extend)
                sup.resource_definitions[extend.to_sym]
              else
                cur.resource(extend)
                cur.resource_definitions[extend.to_sym]
              end
            class_eval &extend_def
            class_eval &block
          end
        else
          block
        end
      const_name = name.to_s.camelcase + 'Resource'
      remove_const(const_name) if const_defined? const_name, false
      name
    end
  end
end
