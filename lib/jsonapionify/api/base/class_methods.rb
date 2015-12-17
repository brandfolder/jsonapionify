require 'active_support/core_ext/class/attribute'

module JSONAPIonify::Api
  module Base::ClassMethods

    def self.extended(klass)
      klass.class_attribute :load_path
    end

    def resource_files
      Dir.glob File.join(load_path, '**/*.rb')
    end

    def resource_signature
      Digest::SHA2.hexdigest resource_files.map { |file| File.read file }.join
    end

    def load_resources
      return unless load_path
      if @last_signature != resource_signature
        @documentation_output = nil
        @last_signature       = resource_signature
        $".delete_if { |s| s.start_with? load_path }
        resource_files.each do |file|
          require file
        end
      end
    end

    def resource_class
      const_get(:ResourceBase, false)
    end

    def documentation_order(resources_in_order)
      @documentation_order = resources_in_order
    end

    def root_url(request)
      URI.parse(request.root_url).tap do |uri|
        sticky_params = sticky_params(request.params)
        uri.query     = sticky_params.to_param if sticky_params.present?
      end.to_s
    end

    def process_index(request)
      headers                    = ContextDelegate.new(request, resource_class.new, resource_class.context_definitions).response_headers
      obj                        = JSONAPIonify.new_object
      obj[:meta]                 = { resources: {} }
      obj[:links]                = { self: request.url }
      obj[:meta][:documentation] = File.join(request.root_url, 'docs')
      obj[:meta][:resources]     = resources.each_with_object({}) do |resource, hash|
        if resource.actions.any? { |action| action.name == :list }
          hash[resource.type] = resource.get_url(root_url(request))
        end
      end
      Rack::Response.new.tap do |response|
        response.status = 200
        headers.each { |k, v| response[k] = v }
        response['content-type'] = 'application/vnd.api+json'
        response.write obj.to_json
      end.finish
    end

    def fields
      resources.each_with_object({}) do |resource, fields|
        fields[resource.type.to_sym] = resource.fields
      end
    end

    def cache(store, *args)
      self.cache_store = ActiveSupport::Cache.lookup_store(store, *args)
    end

    def cache_store=(store)
      @cache_store = store
    end

    def cache_store
      @cache_store ||= JSONAPIonify.cache_store
    end
  end
end
