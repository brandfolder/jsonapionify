require 'rack/test'
require 'active_support/concern'

module JSONAPIonify
  module Api::TestHelper
    extend ActiveSupport::Concern
    include Rack::Test::Methods

    module ClassMethods
      def set_api(api)
        define_method(:app) do
          api
        end
      end
    end

    def set_headers
      @set_headers ||= Rack::Utils::HeaderHash.new
    end

    def json(hash)
      Oj.dump hash.deep_stringify_keys
    end

    def last_response_json
      Oj.load last_response.body
    end

    def header(name, value)
      set_headers[name] = value
      super
    end

    def content_type(value)
      header('content-type', value)
    end

    def accept(*values)
      header('accept', values.join(','))
    end

    def delete(*args, &block)
      header('content-type', set_headers['content-type'].to_s)
      super
    end

    def authorization(type, value)
      header 'Authorization', [type, value].join(' ')
    end

  end
end
