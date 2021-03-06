module JSONAPIonify::Api
  class Response
    using JSONAPIonify::DestructuredProc

    attr_reader :action, :accept, :response_block, :status,
                :matcher, :content_type, :extension, :example_accept

    def initialize(action, accept: 'application/vnd.api+json', content_type: nil, status: nil, match: nil, cacheable: true, extension: nil, &block)
      accept          = MIME::Types.type_for("ex.#{extension}")[0]&.content_type if extension
      @extension      = extension.to_s if extension
      @action         = action
      @response_block = block || proc {}
      @accept         = accept unless match
      @example_accept = accept
      @content_type   = content_type || (@accept == '*/*' ? nil : @accept)
      @matcher        = match || proc {}
      @status         = status || 200
      @cacheable      = cacheable
    end

    def cacheable
      action.cacheable && @cacheable
    end

    def ==(other)
      self.class == other.class &&
        %i{@accept}.all? do |ivar|
          instance_variable_get(ivar) == other.instance_variable_get(ivar)
        end
    end

    def documentation_object
      OpenStruct.new(
        accept:       accept,
        content_type: accept,
        status:       status
      )
    end

    def call(instance, context, status: nil)
      status   ||= self.status
      response = self
      instance.instance_eval do
        body = instance_exec(context, &response.response_block.destructure)
        Rack::Response.new.tap do |rack_response|
          rack_response.status = status
          response_headers.each do |k, v|
            rack_response.headers[k.split('-').map(&:capitalize).join('-')] = v
          end
          rack_response.headers['Content-Type'] =
            case response.content_type
            when nil
              raise(Errors::MissingContentType, 'missing content type')
            when Proc
              response.content_type.call(context)
            else
              response.content_type
            end
          if body.respond_to?(:each)
            rack_response.body = body
          elsif !body.nil?
            rack_response.write(body)
          end
        end.finish
      end
    end

    def accept_with_header?(accept:, extension:)
      self.accept == accept || (self.accept == '*/*' && !extension) || (accept == '*/*' && !extension)
    end

    def accept_with_matcher?(context)
      !!matcher.call(context)
    end

  end
end
